import Foundation

struct CaptureSession: Codable {
    var id: SessionID
    var status: SessionStatus
    var startTime: Timestamp?
    var endTime: Timestamp?
    var framesCaptured: UInt16 = 0
    var coverageMap: CoverageMap? // note: CoverageMap not Codable fully
}
