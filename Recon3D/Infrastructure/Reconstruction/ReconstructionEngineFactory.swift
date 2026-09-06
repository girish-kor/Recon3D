import Foundation

class ReconstructionEngineFactory {
    static func createEngine(capabilities: DeviceCapabilities, jobStore: JobStoreProtocol, checkpointManager: CheckpointManagerProtocol) -> ReconstructionEngineProtocol {
        if capabilities.supportsDepthAPI && capabilities.supportsAR {
            return ARKitLiDAREngine(jobStore: jobStore, checkpointManager: checkpointManager)
        } else {
            // Fallback to OpenCV SfM (bridge to C++). For brevity, we'll use ARKit fallback.
            return ARKitLiDAREngine(jobStore: jobStore, checkpointManager: checkpointManager)
        }
    }
}
