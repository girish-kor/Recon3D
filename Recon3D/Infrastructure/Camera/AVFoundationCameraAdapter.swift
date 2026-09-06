import AVFoundation
import UIKit
import os.log

class AVFoundationCameraAdapter: NSObject, CameraAdapterProtocol, AVCaptureVideoDataOutputSampleBufferDelegate {
    private let logger = OSLog(subsystem: "com.recon3d", category: "CameraAdapter")
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var depthOutput: AVCaptureDepthDataOutput?
    private var sessionQueue = DispatchQueue(label: "camera.session.queue")
    private var activeHandle: CameraSessionHandle?
    private var currentPose: CameraPose? // from ARKit or fallback
    var onFrameReceived: ((Frame) -> Void)?
    private var frameCounter: FrameID = 0
    private let sessionID = UUID()
    
    func requestPermissions() -> PermissionStatus {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let storageStatus = true // check later
        return PermissionStatus(camera: cameraStatus == .authorized,
                                storage: true,
                                microphone: true)
    }
    
    func detectCapabilities() -> DeviceCapabilities {
        return SystemCapabilities.current()
    }
    
    func initializeSession(config: CaptureConfig) throws -> CameraSessionHandle {
        let session = AVCaptureSession()
        session.beginConfiguration()
        session.sessionPreset = .photo // high quality
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            throw NSError(domain: "Camera", code: 300, userInfo: nil)
        }
        
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw NSError(domain: "Camera", code: 300, userInfo: nil) }
        session.addInput(input)
        
        let output = AVCaptureVideoDataOutput()
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        output.setSampleBufferDelegate(self, queue: sessionQueue)
        guard session.canAddOutput(output) else { throw NSError(domain: "Camera", code: 300, userInfo: nil) }
        session.addOutput(output)
        videoOutput = output
        
        // Depth if available
        if let depthDevice = AVCaptureDevice.default(.builtInLiDARDepthCamera, for: .video, position: .back),
           config.enableDepthSensorIfAvailable {
            let depthOutput = AVCaptureDepthDataOutput()
            depthOutput.setDelegate(self, callbackQueue: sessionQueue)
            if session.canAddOutput(depthOutput) {
                session.addOutput(depthOutput)
                self.depthOutput = depthOutput
            }
        }
        
        session.commitConfiguration()
        captureSession = session
        let handle = UUID()
        activeHandle = handle
        return handle
    }
    
    func startCapture(handle: CameraSessionHandle) throws {
        guard handle == activeHandle else { throw NSError(domain: "Camera", code: 301, userInfo: nil) }
        sessionQueue.async {
            self.captureSession?.startRunning()
        }
    }
    
    func stopCapture(handle: CameraSessionHandle) throws {
        guard handle == activeHandle else { throw NSError(domain: "Camera", code: 301, userInfo: nil) }
        sessionQueue.async {
            self.captureSession?.stopRunning()
        }
    }
    
    func getCurrentPose(handle: CameraSessionHandle) -> CameraPose? {
        // In real implementation, use ARKit or device motion
        // For now return a dummy pose
        return CameraPose(rotation: simd_float3x3(diagonal: simd_float3(1,1,1)),
                          translation: simd_float3(0,0,0),
                          covariance: nil,
                          confidence: 0.8,
                          timestamp: Date().nanoseconds)
    }
    
    func setFocusMode(_ mode: FocusMode, handle: CameraSessionHandle) throws {}
    func setExposureMode(_ mode: ExposureMode, handle: CameraSessionHandle) throws {}
    func release(handle: CameraSessionHandle) throws {
        captureSession?.stopRunning()
        captureSession = nil
        activeHandle = nil
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let frameID = frameCounter; frameCounter += 1
        
        // Build metadata (simplified)
        var meta = FrameMetadata()
        meta.exposureTime = 30
        meta.iso = 100
        meta.sharpnessScore = 50 // would compute
        meta.luminanceMean = 0.5
        meta.luminanceStdDev = 0.1
        meta.contrast = 0.5
        if let pose = getCurrentPose(handle: activeHandle!) {
            meta.cameraPose = pose
        }
        
        let frame = Frame(id: frameID,
                          sessionID: sessionID,
                          timestamp: timestamp.nanoseconds,
                          imageBuffer: pixelBuffer,
                          depthMap: nil,
                          metadata: meta)
        onFrameReceived?(frame)
    }
}

extension CMTime {
    var nanoseconds: UInt64 {
        return UInt64(self.value) * 1_000_000_000 / UInt64(self.timescale)
    }
}

// Depth output delegate stub
extension AVFoundationCameraAdapter: AVCaptureDepthDataOutputDelegate {
    func depthDataOutput(_ output: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
        // Handle depth
    }
}
