import Foundation

class FileSystemRepository: PersistenceRepositoryProtocol {
    private let rootDir: URL
    private let fileManager = FileManager.default
    private let lock = NSLock()
    private let metadataPath: URL
    
    init(rootDir: URL) throws {
        self.rootDir = rootDir
        self.metadataPath = rootDir.appendingPathComponent("metadata.json")
        try fileManager.createDirectory(at: rootDir, withIntermediateDirectories: true, attributes: nil)
    }
    
    func saveModel(_ asset: ModelAsset) throws -> ModelID {
        lock.lock(); defer { lock.unlock() }
        let dir = rootDir.appendingPathComponent(asset.id.uuidString)
        try fileManager.createDirectory(at: dir, withIntermediateDirectories: true, attributes: nil)
        
        // Write mesh binary
        let meshData = try JSONEncoder().encode(asset.mesh)
        try meshData.write(to: dir.appendingPathComponent("mesh.bin"))
        // Write textures
        for (index, texture) in asset.textures.enumerated() {
            try texture.imageData.write(to: dir.appendingPathComponent("tex_\(index).png"))
        }
        // Write materials
        let matData = try JSONEncoder().encode(asset.materials)
        try matData.write(to: dir.appendingPathComponent("materials.json"))
        // Write thumbnail
        try asset.thumbnailImage.write(to: dir.appendingPathComponent("thumb.jpg"))
        // Write manifest
        let manifest: [String: Any] = [
            "id": asset.id.uuidString,
            "sessionID": asset.sessionID.uuidString,
            "jobID": asset.jobID.uuidString,
            "createdAt": asset.createdAt,
            "fileSizeBytes": asset.fileSizeBytes,
            "qualityReport": try JSONEncoder().encode(asset.qualityReport),
            "vertexCount": asset.mesh.vertices.count,
            "textureCount": asset.textures.count
        ]
        let manifestData = try JSONSerialization.data(withJSONObject: manifest, options: .prettyPrinted)
        try manifestData.write(to: dir.appendingPathComponent("manifest.json"))
        return asset.id
    }
    
    func loadModel(_ id: ModelID) throws -> ModelAsset? {
        lock.lock(); defer { lock.unlock() }
        let dir = rootDir.appendingPathComponent(id.uuidString)
        guard fileManager.fileExists(atPath: dir.path) else { return nil }
        let meshData = try Data(contentsOf: dir.appendingPathComponent("mesh.bin"))
        let mesh = try JSONDecoder().decode(Mesh.self, from: meshData)
        // Load textures
        var textures: [Texture] = []
        let texFiles = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.lastPathComponent.hasPrefix("tex_") }
        for file in texFiles {
            let data = try Data(contentsOf: file)
            // derive width/height from image (simplified)
            textures.append(Texture(id: UUID(), name: file.lastPathComponent, imageData: data, width: 1024, height: 1024, channels: 4, type: .diffuse, uvChannel: 0))
        }
        let matData = try Data(contentsOf: dir.appendingPathComponent("materials.json"))
        let materials = try JSONDecoder().decode([Material].self, from: matData)
        let manifestData = try Data(contentsOf: dir.appendingPathComponent("manifest.json"))
        let manifest = try JSONSerialization.jsonObject(with: manifestData) as? [String: Any]
        let qualityData = manifest?["qualityReport"] as? Data ?? Data()
        let quality = try JSONDecoder().decode(QualityReport.self, from: qualityData)
        let thumbData = try Data(contentsOf: dir.appendingPathComponent("thumb.jpg"))
        return ModelAsset(id: id, sessionID: UUID(), jobID: UUID(), mesh: mesh, textures: textures, materials: materials,
                          qualityReport: quality, thumbnailImage: thumbData, previewMesh: mesh,
                          createdAt: manifest?["createdAt"] as? Timestamp ?? 0,
                          fileSizeBytes: manifest?["fileSizeBytes"] as? UInt64 ?? 0,
                          filePath: dir.path, metadata: [:])
    }
    
    func deleteModel(_ id: ModelID) throws {
        lock.lock(); defer { lock.unlock() }
        let dir = rootDir.appendingPathComponent(id.uuidString)
        if fileManager.fileExists(atPath: dir.path) {
            try fileManager.removeItem(at: dir)
        }
    }
    
    func listModels() -> [ModelID] {
        lock.lock(); defer { lock.unlock() }
        guard let contents = try? fileManager.contentsOfDirectory(at: rootDir, includingPropertiesForKeys: nil) else { return [] }
        return contents.filter { $0.hasDirectoryPath && $0.lastPathComponent != ".trash" }
            .compactMap { ModelID(uuidString: $0.lastPathComponent) }
    }
    
    func recoverFromCorruption(_ id: ModelID) throws -> ModelAsset? {
        // Attempt to rebuild from partial files
        return nil
    }
}
