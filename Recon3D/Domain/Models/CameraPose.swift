import Foundation
import simd
struct CameraPose: Codable {
    var rotation: simd_float3x3
    var translation: simd_float3
    var covariance: simd_float3x3? // simplified as 3x3
    var confidence: Float
    var timestamp: Timestamp
}
