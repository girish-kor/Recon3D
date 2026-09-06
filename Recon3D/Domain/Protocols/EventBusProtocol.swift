import Foundation

protocol EventBusProtocol {
    func publish(_ event: Any)
    func subscribe<T>(_ type: T.Type, handler: @escaping (T) -> Void) -> AnyCancellable
}

typealias AnyCancellable = UUID // simple

// Event types
struct FrameCapturedEvent { let frameID: FrameID; let bufferSize: Int }
struct FrameRejectedEvent { let frameID: FrameID; let verdict: QualityVerdict }
struct TrackingLostEvent {}
struct BufferFullEvent {}
struct SessionStartedEvent { let sessionID: SessionID }
struct SessionPausedEvent {}
struct SessionResumedEvent {}
struct ReconstructionStartedEvent { let jobID: JobID }
struct ProgressUpdateEvent { let progress: Float; let stage: ReconstructionStage; let stageProgress: Float }
struct ReconstructionCompletedEvent { let asset: ModelAsset }
struct ReconstructionCancelledEvent {}
struct ReconstructionRetryEvent {}
struct ReconstructionResumedEvent {}
struct ErrorOccurredEvent { let error: ErrorState }
struct FatalErrorEvent { let error: ErrorState }
struct UserActionRequiredEvent { let error: ErrorState }
struct StateChangedEvent { let state: SessionStatus; let subState: String }
struct NeedMoreFramesEvent {}
struct ExportProgressEvent { let jobID: ExportJobID; let progress: Float }
struct ExportCompletedEvent { let jobID: ExportJobID; let url: URL }
struct ExportFailedEvent { let jobID: ExportJobID; let error: ErrorState }
