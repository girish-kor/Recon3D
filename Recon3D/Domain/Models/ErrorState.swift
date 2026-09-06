import Foundation

struct ErrorState: Codable {
    var code: ErrorCode
    var message: String
    var details: [String: String] = [:]
    var retryable: Bool
    var userRecoverable: Bool
    var timestamp: Timestamp
    var stage: ReconstructionStage?
    var recoverySuggestion: RecoverySuggestion
}
