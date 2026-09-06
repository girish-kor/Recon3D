import Foundation
import simd
import CoreVideo
typealias FrameID = UInt64
typealias Timestamp = UInt64 // nanoseconds since epoch

struct FrameMetadata: Codable {
    var exposureTime: Milliseconds = 30
    var iso: UInt16 = 100
    var focusDistance: Float = 1.0
    var focusConfidence: Float = 1.0
    var motionBlurMagnitude: Float = 0.0
    var sharpnessScore: Float = 100.0
    var luminanceMean: Float = 0.5
    var luminanceStdDev: Float = 0.1
    var contrast: Float = 0.5
    var gyroData: simd_float3 = .zero
    var accelerometer: simd_float3 = .zero
    var deviceOrientation: simd_quatf = .identity
    var cameraPose: CameraPose?
    var depthMap: Data? // raw depth buffer (optional)
    var thermalStateAtCapture: Float = 25.0
}

struct CoverageContribution: Codable {
    var azimuthDeg: Degrees
    var elevationDeg: Degrees
    var binIndexAz: UInt8
    var binIndexEl: UInt8
}

class Frame: CustomStringConvertible {
    let id: FrameID
    let sessionID: SessionID
    let timestamp: Timestamp
    var imageBuffer: CVPixelBuffer // owned
    var depthMap: CVPixelBuffer? // optional
    var metadata: FrameMetadata
    var qualityVerdict: QualityVerdict = .pass
    var coverageContribution: CoverageContribution?
    
    init(id: FrameID, sessionID: SessionID, timestamp: Timestamp, imageBuffer: CVPixelBuffer, depthMap: CVPixelBuffer? = nil, metadata: FrameMetadata) {
        self.id = id
        self.sessionID = sessionID
        self.timestamp = timestamp
        self.imageBuffer = imageBuffer
        self.depthMap = depthMap
        self.metadata = metadata
    }
    
    var description: String { "Frame \(id) at \(timestamp)" }
}

typealias SessionID = UUID
typealias Degrees = Float
typealias Milliseconds = UInt32
typealias JobID = UUID
typealias ModelID = UUID
typealias ExportJobID = UUID
typealias FilePath = String
