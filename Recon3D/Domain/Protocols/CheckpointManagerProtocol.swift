import Foundation

protocol CheckpointManagerProtocol {
    func save(jobID: JobID, stage: ReconstructionStage, data: Data) throws -> FilePath
    func load(jobID: JobID, stage: ReconstructionStage) throws -> Data?
    func deleteCheckpoint(jobID: JobID) throws
    func listCheckpoints(jobID: JobID) -> [ReconstructionStage]
}
