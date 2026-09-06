import Foundation

protocol CameraAdapterProtocol {
    func requestPermissions() -> PermissionStatus
    func detectCapabilities() -> DeviceCapabilities
    func initializeSession(config: CaptureConfig) throws -> CameraSessionHandle
    func startCapture(handle: CameraSessionHandle) throws
    func stopCapture(handle: CameraSessionHandle) throws
    func getCurrentPose(handle: CameraSessionHandle) -> CameraPose?
    func setFocusMode(_ mode: FocusMode, handle: CameraSessionHandle) throws
    func setExposureMode(_ mode: ExposureMode, handle: CameraSessionHandle) throws
    func release(handle: CameraSessionHandle) throws
    var onFrameReceived: ((Frame) -> Void)? { get set }
}

typealias CameraSessionHandle = UUID

struct PermissionStatus {
    var camera: Bool
    var storage: Bool
    var microphone: Bool
}
