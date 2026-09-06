import Foundation
import os.log
import simd
import CoreVideo

class ReconstructionOrchestrator {
    private let logger = OSLog(subsystem: "com.recon3d", category: "Orchestrator")
    private let stateLock = NSRecursiveLock()
    private(set) var state: SessionStatus = .idle
    private(set) var subState: String = "none"
    private var sessionID: SessionID?
    private var sessionHandle: CameraSessionHandle?
    private var frameBufferManager: FrameBufferManagerProtocol
    private var coverageMap = CoverageMap()
    private var currentJob: ReconstructionJob?
    private var currentAsset: ModelAsset?
    private var currentExportJob: ExportJob?
    private var config: ProcessingConfiguration
    private var caps: DeviceCapabilities
    private let cameraAdapter: CameraAdapterProtocol
    private let engine: ReconstructionEngineProtocol
    private let repo: PersistenceRepositoryProtocol
    private let exportService: ExportServiceProtocol
    private let eventBus: EventBusProtocol
    private var cancellables: [AnyCancellable] = []
    private var progressMonitorTask: Task<Void, Never>?
    
    init(cameraAdapter: CameraAdapterProtocol,
         engine: ReconstructionEngineProtocol,
         repo: PersistenceRepositoryProtocol,
         exportService: ExportServiceProtocol,
         eventBus: EventBusProtocol,
         config: ProcessingConfiguration,
         caps: DeviceCapabilities) {
        self.cameraAdapter = cameraAdapter
        self.engine = engine
        self.repo = repo
        self.exportService = exportService
        self.eventBus = eventBus
        self.config = config
        self.caps = caps
        self.frameBufferManager = RingBufferFrameManager(capacity: Int(config.capture.maxFramesToCapture))
        setupSubscriptions()
    }
    
    private func setupSubscriptions() {
        // In production, use Combine or similar. We'll use a simple closure.
        cameraAdapter.onFrameReceived = { [weak self] frame in
            self?.onFrameReceived(frame)
        }
        // Subscribe to reconstruction completion via engine's internal event bus? We'll poll or use callbacks.
        // For simplicity, we'll poll in the progress monitor.
    }
    
    func bootstrap() {
        stateLock.lock(); defer { stateLock.unlock() }
        // Already set in init, but we can reload config/caps
        config = ConfigurationLoader.loadConfiguration()
        caps = SystemCapabilities.current()
        recoverInterruptedJobs()
        state = .idle
        subState = "none"
        eventBus.publish(StateChangedEvent(state: state, subState: subState))
    }
    
    private func recoverInterruptedJobs() {
        let pending = engine.jobStore.findByStatus([.running, .paused])
        for job in pending {
            if let checkpointPath = job.checkpointPath, FileManager.default.fileExists(atPath: checkpointPath) {
                do {
                    try engine.resumeJob(job)
                    currentJob = job
                    state = .active // but we need to differentiate processing
                    subState = "processing"
                    eventBus.publish(StateChangedEvent(state: state, subState: subState))
                    startProgressMonitoring(jobID: job.id)
                    os_log("Resumed job %@", log: logger, type: .info, job.id.uuidString)
                    return
                } catch {
                    os_log("Failed to resume job %@: %@", log: logger, type: .error, job.id.uuidString, error.localizedDescription)
                }
            }
            // Mark as failed
            job.status = .failed
            job.errorState = ErrorState(code: .sysAppTerminated,
                                        message: "App terminated during processing",
                                        retryable: true,
                                        userRecoverable: false,
                                        timestamp: Date().nanoseconds,
                                        stage: job.stage,
                                        recoverySuggestion: .retry)
            engine.jobStore.update(job)
        }
    }
    
    func startCaptureSession() {
        stateLock.lock(); defer { stateLock.unlock() }
        guard state == .idle || state == .error else { return }
        
        // Permissions
        let perms = cameraAdapter.requestPermissions()
        if !perms.camera || !perms.storage {
            setError(code: .permissionCameraDenied, retryable: true, userRecoverable: true)
            return
        }
        
        // Capabilities
        caps = SystemCapabilities.current()
        if caps.freeStorageBytes < config.system.minAvailableDiskMB * 1024 * 1024 {
            setError(code: .ioSpaceExhausted, retryable: true, userRecoverable: true)
            return
        }
        if caps.thermalState == .critical {
            setError(code: .capThermalThrottle, retryable: false, userRecoverable: true)
            return
        }
        
        do {
            let handle = try cameraAdapter.initializeSession(config: config.capture)
            self.sessionHandle = handle
            self.sessionID = UUID()
            try cameraAdapter.startCapture(handle: handle)
            state = .active
            subState = "capturing"
            frameBufferManager.clear()
            coverageMap = CoverageMap()
            eventBus.publish(SessionStartedEvent(sessionID: sessionID!))
        } catch {
            setError(code: .camInitFail, retryable: true)
        }
    }
    
    private func onFrameReceived(_ frame: Frame) {
        stateLock.lock()
        guard state == .active && subState == "capturing" else { stateLock.unlock(); return }
        stateLock.unlock()
        
        // Attach pose if missing
        var frame = frame
        if frame.metadata.cameraPose == nil, let handle = sessionHandle {
            if let pose = cameraAdapter.getCurrentPose(handle: handle) {
                frame.metadata.cameraPose = pose
            }
        }
        guard let pose = frame.metadata.cameraPose else {
            eventBus.publish(TrackingLostEvent())
            return
        }
        if pose.confidence < 0.3 {
            eventBus.publish(TrackingLostEvent())
            return
        }
        
        // Quality evaluation
        let verdict = evaluateFrameQuality(frame)
        frame.qualityVerdict = verdict
        if verdict != .pass {
            eventBus.publish(FrameRejectedEvent(frameID: frame.id, verdict: verdict))
            return
        }
        
        // Coverage contribution
        let contrib = computeCoverageContribution(pose)
        frame.coverageContribution = contrib
        stateLock.lock()
        coverageMap.update(with: contrib, confidence: pose.confidence)
        stateLock.unlock()
        
        // Add to buffer
        let added = frameBufferManager.addFrame(frame)
        if !added {
            eventBus.publish(BufferFullEvent())
        }
        eventBus.publish(FrameCapturedEvent(frameID: frame.id, bufferSize: frameBufferManager.size))
        
        // Check stop conditions
        if frameBufferManager.size >= Int(config.capture.minFramesRequired) {
            stateLock.lock()
            let sufficient = coverageMap.isSufficient(requiredAzimuthBins: config.capture.coverageRequiredAzimuthBins,
                                                      requiredElevationBins: config.capture.coverageRequiredElevationBins,
                                                      minFramesPerBin: config.capture.coverageMinFramesPerBin)
            stateLock.unlock()
            if sufficient && config.capture.autoStop {
                stopCaptureAndReconstruct()
            }
        }
    }
    
    private func evaluateFrameQuality(_ frame: Frame) -> QualityVerdict {
        let meta = frame.metadata
        // Motion blur
        let gyroMagnitude = simd_length(meta.gyroData) * Float(meta.exposureTime) / 1000.0
        if gyroMagnitude > 0.05 { return .rejectMotion }
        // Sharpness using Laplacian variance (simplified)
        guard let sharpness = computeSharpness(frame.imageBuffer) else { return .rejectCorrupt }
        if sharpness < config.capture.sharpnessThreshold { return .rejectFocus }
        // Focus confidence
        if config.capture.focusMode == .locked && meta.focusConfidence < 0.7 { return .rejectFocus }
        // Exposure
        if meta.luminanceMean < config.capture.luminanceMin || meta.luminanceMean > config.capture.luminanceMax {
            return .rejectExposure
        }
        if meta.luminanceStdDev < 0.05 { return .rejectContrast }
        let contrast = (meta.luminanceMax - meta.luminanceMin) / (meta.luminanceMax + meta.luminanceMin + 0.001)
        if contrast < config.capture.contrastThreshold / 100.0 { return .rejectContrast }
        return .pass
    }
    
    
    private func computeCoverageContribution(_ pose: CameraPose) -> CoverageContribution {
        // Use rotation matrix to get look direction
        let lookDir = simd_normalize(pose.rotation * simd_float3(0, 0, -1))
        let azimuth = atan2(lookDir.x, lookDir.z) * 180 / Float.pi
        let azimuthDeg = (azimuth + 360).truncatingRemainder(dividingBy: 360)
        let elevation = asin(lookDir.y) * 180 / Float.pi
        let elevationDeg = min(max(elevation, -90), 90)
        let binAz = UInt8(floor(azimuthDeg / 10)) % 36
        let binEl = UInt8(floor((elevationDeg + 90) / 10)) % 18
        return CoverageContribution(azimuthDeg: azimuthDeg, elevationDeg: elevationDeg,
                                    binIndexAz: binAz, binIndexEl: binEl)
    }
    
    func pauseCapture() {
        stateLock.lock(); defer { stateLock.unlock() }
        guard state == .active && subState == "capturing" else { return }
        guard let handle = sessionHandle else { return }
        do {
            try cameraAdapter.stopCapture(handle: handle)
            subState = "paused"
            eventBus.publish(SessionPausedEvent())
        } catch {
            os_log("Pause failed: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    func resumeCapture() {
        stateLock.lock(); defer { stateLock.unlock() }
        guard state == .active && subState == "paused" else { return }
        guard let handle = sessionHandle else { return }
        do {
            try cameraAdapter.startCapture(handle: handle)
            subState = "capturing"
            eventBus.publish(SessionResumedEvent())
        } catch {
            setError(code: .camStreamFail, retryable: true)
        }
    }
    
    func stopCaptureAndReconstruct() {
        stateLock.lock()
        guard state == .active && (subState == "capturing" || subState == "paused") else {
            stateLock.unlock(); return
        }
        guard let handle = sessionHandle else { stateLock.unlock(); return }
        do {
            try cameraAdapter.stopCapture(handle: handle)
        } catch {
            os_log("Stop capture error: %@", log: logger, type: .error, error.localizedDescription)
        }
        state = .active
        subState = "processing"
        stateLock.unlock()
        
        let frames = frameBufferManager.getFramesForReconstruction(config: config.reconstruction)
        if frames.count < Int(config.capture.minFramesRequired) {
            setError(code: .covInsufficientCoverage, retryable: true, userRecoverable: true)
            return
        }
        do {
            let job = try engine.createJob(config: config.reconstruction, frames: frames)
            currentJob = job
            try engine.submitJob(job)
            eventBus.publish(ReconstructionStartedEvent(jobID: job.id))
            startProgressMonitoring(jobID: job.id)
        } catch {
            setError(code: .reconAlignmentFail, retryable: true)
        }
    }
    
    private func startProgressMonitoring(jobID: JobID) {
        progressMonitorTask = Task { [weak self] in
            guard let self = self else { return }
            while !Task.isCancelled {
                if let progress = self.engine.getProgress(jobID: jobID) {
                    self.eventBus.publish(ProgressUpdateEvent(progress: progress.progress,
                                                              stage: progress.stage,
                                                              stageProgress: progress.currentStageProgress))
                    if progress.progress >= 1.0 {
                        // completion will be handled after job finishes
                        break
                    }
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            // Fetch result
            do {
                let asset = try self.engine.getResult(jobID: jobID)
                self.stateLock.lock()
                self.currentAsset = asset
                self.state = .completed
                self.subState = "completed"
                self.stateLock.unlock()
                self.eventBus.publish(ReconstructionCompletedEvent(asset: asset))
                // Save to repository
                _ = try self.repo.saveModel(asset)
            } catch {
                if let error = self.engine.getError(jobID: jobID) {
                    self.handleError(error)
                } else {
                    self.setError(code: .reconIntermediateCorrupt, retryable: false)
                }
            }
        }
    }
    
    func retryReconstruction() {
        stateLock.lock()
        guard state == .error, let job = currentJob, let error = job.errorState, error.retryable else {
            stateLock.unlock(); return
        }
        job.retryCount += 1
        if job.retryCount > job.maxRetries {
            setError(code: .reconAlignmentFail, retryable: false)
            stateLock.unlock()
            return
        }
        let frames = frameBufferManager.getFramesForReconstruction(config: config.reconstruction)
        if frames.count < Int(config.capture.minFramesRequired) {
            // need more frames
            state = .active
            subState = "capturing"
            stateLock.unlock()
            if let handle = sessionHandle {
                do { try cameraAdapter.startCapture(handle: handle) } catch {}
            }
            eventBus.publish(NeedMoreFramesEvent())
            return
        }
        // resubmit
        do {
            let newJob = try engine.createJob(config: config.reconstruction, frames: frames)
            currentJob = newJob
            state = .active
            subState = "processing"
            stateLock.unlock()
            try engine.submitJob(newJob)
            eventBus.publish(ReconstructionRetryEvent())
            startProgressMonitoring(jobID: newJob.id)
        } catch {
            setError(code: .reconAlignmentFail, retryable: true)
            stateLock.unlock()
        }
    }
    
    func cancelReconstruction() {
        stateLock.lock(); defer { stateLock.unlock() }
        guard let job = currentJob, job.status == .running || job.status == .pending || job.status == .paused else { return }
        engine.cancelJob(job)
        progressMonitorTask?.cancel()
        state = .idle
        subState = "none"
        currentJob = nil
        cleanupTempFiles()
        eventBus.publish(ReconstructionCancelledEvent())
    }
    
    private func handleError(_ error: ErrorState) {
        stateLock.lock()
        state = .error
        subState = "error"
        stateLock.unlock()
        eventBus.publish(ErrorOccurredEvent(error: error))
        if error.userRecoverable {
            eventBus.publish(UserActionRequiredEvent(error: error))
        } else if error.retryable {
            retryReconstruction()
        } else {
            eventBus.publish(FatalErrorEvent(error: error))
        }
    }
    
    private func setError(code: ErrorCode, retryable: Bool, userRecoverable: Bool = false) {
        let error = ErrorState(code: code,
                               message: "Error \(code.rawValue)",
                               retryable: retryable,
                               userRecoverable: userRecoverable,
                               timestamp: Date().nanoseconds,
                               stage: currentJob?.stage,
                               recoverySuggestion: .retry)
        handleError(error)
    }
    
    private func cleanupTempFiles() {
        // Remove checkpoint files, temp directories
    }
    
    func resumeAfterInterruption() {
        recoverInterruptedJobs()
    }
    
    func deleteModel(id: ModelID) {
        do {
            try repo.deleteModel(id)
        } catch {
            os_log("Delete failed: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    func exportModel(assetID: ModelID, format: ExportFormat) {
        guard let asset = try? repo.loadModel(assetID) else { return }
        do {
            let job = try exportService.exportModel(asset, format: format, options: ExportOptions())
            currentExportJob = job
            // Monitor export progress via event bus
        } catch {
            setError(code: .exportTranscodingFail, retryable: true)
        }
    }
}

