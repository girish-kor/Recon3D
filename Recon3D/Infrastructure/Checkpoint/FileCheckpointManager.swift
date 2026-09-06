import Foundation

class FileCheckpointManager: CheckpointManagerProtocol {
    private let checkpointDir: URL
    private let fileManager = FileManager.default
    
    init(baseDir: URL) throws {
        self.checkpointDir = baseDir.appendingPathComponent("checkpoints")
        try fileManager.createDirectory(at: checkpointDir, withIntermediateDirectories: true, attributes: nil)
    }
    
    func save(jobID: JobID, stage: ReconstructionStage, data: Data) throws -> FilePath {
        let jobDir = checkpointDir.appendingPathComponent(jobID.uuidString)
        try fileManager.createDirectory(at: jobDir, withIntermediateDirectories: true, attributes: nil)
        let file = jobDir.appendingPathComponent("stage_\(stage.rawValue).bin")
        try data.write(to: file)
        return file.path
    }
    
    func load(jobID: JobID, stage: ReconstructionStage) throws -> Data? {
        let file = checkpointDir.appendingPathComponent(jobID.uuidString).appendingPathComponent("stage_\(stage.rawValue).bin")
        guard fileManager.fileExists(atPath: file.path) else { return nil }
        return try Data(contentsOf: file)
    }
    
    func deleteCheckpoint(jobID: JobID) throws {
        let dir = checkpointDir.appendingPathComponent(jobID.uuidString)
        if fileManager.fileExists(atPath: dir.path) {
            try fileManager.removeItem(at: dir)
        }
    }
    
    func listCheckpoints(jobID: JobID) -> [ReconstructionStage] {
        let dir = checkpointDir.appendingPathComponent(jobID.uuidString)
        guard let files = try? fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return [] }
        return files.compactMap { url in
            let name = url.lastPathComponent
            if let range = name.range(of: "stage_"), let raw = Int(name[range.upperBound...].dropLast(4)) {
                return ReconstructionStage(rawValue: raw)
            }
            return nil
        }
    }
}
