import Foundation

class ReconstructionJob: Codable {
    var id: JobID
    var sessionID: SessionID
    var status: JobStatus = .pending
    var stage: ReconstructionStage = .preprocessing
    var progressPercentage: Float = 0.0
    var currentStageProgress: Float = 0.0
    var framesUsed: [FrameID] = []
    var framesTotal: UInt16 = 0
    var createdAt: Timestamp
    var startedAt: Timestamp?
    var completedAt: Timestamp?
    var checkpointPath: FilePath?
    var resultAssetID: ModelID?
    var errorState: ErrorState?
    var retryCount: UInt8 = 0
    var maxRetries: UInt8 = 3
    var config: ReconstructionConfig
    var cancellationRequested: Bool = false
    var pauseRequested: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, sessionID, status, stage, progressPercentage, currentStageProgress,
             framesUsed, framesTotal, createdAt, startedAt, completedAt,
             checkpointPath, resultAssetID, errorState, retryCount, maxRetries, config,
             cancellationRequested, pauseRequested
    }
    
    init() {
        self.id = UUID()
        self.sessionID = UUID()
        self.createdAt = Date().nanoseconds
        self.config = ReconstructionConfig()
    }
}
