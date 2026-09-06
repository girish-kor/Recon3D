import Foundation

class CaptureAndReconstructUseCase {
    private let orchestrator: ReconstructionOrchestrator
    
    init(orchestrator: ReconstructionOrchestrator) {
        self.orchestrator = orchestrator
    }
    
    func execute() {
        orchestrator.startCaptureSession()
    }
    
    func stopAndReconstruct() {
        orchestrator.stopCaptureAndReconstruct()
    }
}
