import Foundation

protocol ReconstructionEngineProtocol {
    func createJob(config: ReconstructionConfig, frames: [Frame]) throws -> ReconstructionJob
    func submitJob(_ job: ReconstructionJob) throws
    func cancelJob(_ job: ReconstructionJob)
    func pauseJob(_ job: ReconstructionJob)
    func resumeJob(_ job: ReconstructionJob) throws
    func getProgress(jobID: JobID) -> (progress: Float, stage: ReconstructionStage, currentStageProgress: Float)?
    func getResult(jobID: JobID) throws -> ModelAsset
    func getError(jobID: JobID) -> ErrorState?
    func checkpointManager: CheckpointManagerProtocol { get }
    var jobStore: JobStoreProtocol { get }
}

protocol JobStoreProtocol {
    func save(_ job: ReconstructionJob)
    func load(_ jobID: JobID) -> ReconstructionJob?
    func update(_ job: ReconstructionJob)
    func findByStatus(_ statuses: [JobStatus]) -> [ReconstructionJob]
}
