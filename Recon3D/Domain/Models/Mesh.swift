import Foundation
import simd
struct Mesh: Codable {
    var vertices: [simd_float3] // length N
    var normals: [simd_float3]? // length N
    var colors: [simd_float3]? // optional
    var indices: [UInt32] // length 3*M
    var uvs: [simd_float2]? // length N
    var vertexQuality: [Float]? // length N
    var boundingBox: (min: simd_float3, max: simd_float3)
}

struct Texture: Codable {
    var id: UUID
    var name: String
    var imageData: Data // PNG/JPEG encoded
    var width: UInt16
    var height: UInt16
    var channels: UInt8
    var type: TextureType
    var uvChannel: UInt8 = 0
}
enum TextureType: String, Codable {
    case diffuse, normal, roughness, metallic, ambientOcclusion, emissive
}

struct Material: Codable {
    var id: UUID
    var name: String
    var properties: [MaterialProperty: MaterialValue]
}
enum MaterialValue: Codable {
    case color(simd_float3)
    case float(Float)
    case textureID(UUID)
    case string(String)
}

struct PointCloud: Codable {
    var points: [simd_float3]
    var colors: [simd_float3]?
    var normals: [simd_float3]?
}

struct ModelAsset: Codable {
    var id: ModelID
    var sessionID: SessionID
    var jobID: JobID
    var mesh: Mesh
    var textures: [Texture]
    var materials: [Material]
    var qualityReport: QualityReport
    var thumbnailImage: Data // JPEG
    var previewMesh: Mesh // decimated
    var createdAt: Timestamp
    var fileSizeBytes: UInt64
    var filePath: FilePath
    var metadata: [String: String]
}

struct QualityReport: Codable {
    var overallScore: Float
    var stageScores: [ReconstructionStage: Float]
    var meshValidity: MeshValidity
    var textureQuality: Float
    var vertexCount: UInt32
    var faceCount: UInt32
    var uvCoverage: Float
    var normalConsistency: Float
    var reconstructionCoverage: Float
    var warnings: [String]
    var errors: [ErrorCode]
}
