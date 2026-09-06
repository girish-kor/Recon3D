import Foundation

protocol PersistenceRepositoryProtocol {
    func saveModel(_ asset: ModelAsset) throws -> ModelID
    func loadModel(_ id: ModelID) throws -> ModelAsset?
    func deleteModel(_ id: ModelID) throws
    func listModels() -> [ModelID]
    func recoverFromCorruption(_ id: ModelID) throws -> ModelAsset?
}
