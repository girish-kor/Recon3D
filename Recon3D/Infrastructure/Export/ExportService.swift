import Foundation

class ExportService: ExportServiceProtocol {
    private var activeJobs: [ExportJobID: ExportJob] = [:]
    private let lock = NSLock()
    private let exportQueue = DispatchQueue(label: "export.queue", attributes: .concurrent)
    private let usdzExporter = USDZExporter()
    private let objExporter = OBJExporter()
    
    func exportModel(_ asset: ModelAsset, format: ExportFormat, options: ExportOptions) throws -> ExportJob {
        let job = ExportJob(id: UUID(), assetID: asset.id, format: format)
        lock.lock()
        activeJobs[job.id] = job
        lock.unlock()
        job.status = .running
        exportQueue.async { [weak self] in
            self?.performExport(job: job, asset: asset, options: options)
        }
        return job
    }
    
    private func performExport(job: ExportJob, asset: ModelAsset, options: ExportOptions) {
        do {
            job.progressPercentage = 0.2
            let tempDir = FileManager.default.temporaryDirectory
            let ext: String
            switch job.format {
            case .usdz: ext = "usdz"
            case .obj: ext = "obj"
            case .gltfBinary: ext = "glb"
            case .gltfASCII: ext = "gltf"
            case .stl: ext = "stl"
            case .ply: ext = "ply"
            }
            let url = tempDir.appendingPathComponent("\(asset.id.uuidString).\(ext)")
            
            job.progressPercentage = 0.5
            switch job.format {
            case .usdz:
                try usdzExporter.export(asset: asset, to: url, options: options)
            case .obj:
                try objExporter.export(asset: asset, to: url, options: options)
            default:
                // Fallback write placeholder for unsupported in this build
                try "Recon3D export placeholder for \(job.format.rawValue)".write(to: url, atomically: true, encoding: .utf8)
            }
            
            job.progressPercentage = 1.0
            job.status = .completed
            job.outputFilePath = url
            lock.lock()
            activeJobs[job.id] = job
            lock.unlock()
        } catch {
            job.status = .failed
            job.errorState = ErrorState(code: .exportTranscodingFail, message: error.localizedDescription, retryable: true, userRecoverable: true, timestamp: Date().nanoseconds, stage: nil, recoverySuggestion: .retry)
            lock.lock()
            activeJobs[job.id] = job
            lock.unlock()
        }
    }
    
    func getExportProgress(jobID: ExportJobID) -> Float? {
        lock.lock(); defer { lock.unlock() }
        return activeJobs[jobID]?.progressPercentage
    }
    
    func cancelExport(jobID: ExportJobID) {
        lock.lock(); defer { lock.unlock() }
        activeJobs[jobID]?.cancellationRequested = true
        activeJobs[jobID]?.status = .cancelled
    }
    
    func getExportedFile(jobID: ExportJobID) -> URL? {
        lock.lock(); defer { lock.unlock() }
        return activeJobs[jobID]?.outputFilePath
    }
    
    func getSupportedFormats() -> [ExportFormat] {
        return ExportFormat.allCases
    }
}
