import Foundation
@testable import Recon3D

class CameraAdapterMock: CameraAdapterProtocol {
    var onFrameReceived: ((Frame) -> Void)?
    func requestPermissions() -> PermissionStatus { PermissionStatus(camera: true, storage: true, microphone: true) }
    func detectCapabilities() -> DeviceCapabilities { SystemCapabilities.current() }
    func initializeSession(config: CaptureConfig) throws -> CameraSessionHandle { UUID() }
    func startCapture(handle: CameraSessionHandle) throws {}
    func stopCapture(handle: CameraSessionHandle) throws {}
    func getCurrentPose(handle: CameraSessionHandle) -> CameraPose? { nil }
    func setFocusMode(_ mode: FocusMode, handle: CameraSessionHandle) throws {}
    func setExposureMode(_ mode: ExposureMode, handle: CameraSessionHandle) throws {}
    func release(handle: CameraSessionHandle) throws {}
}
