import Foundation

protocol ExportServiceProtocol {
    func exportModel(_ asset: ModelAsset, format: ExportFormat, options: ExportOptions) throws -> ExportJob
    func getExportProgress(jobID: ExportJobID) -> Float?
    func cancelExport(jobID: ExportJobID)
    func getExportedFile(jobID: ExportJobID) -> URL?
    func getSupportedFormats() -> [ExportFormat]
}

struct ExportOptions {
    var textureCompression: Float = 0.9
    var includeNormals: Bool = true
    var includeUVs: Bool = true
    var triangulate: Bool = true
}

class ExportJob {
    var id: ExportJobID
    var assetID: ModelID
    var format: ExportFormat
    var status: JobStatus = .pending
    var progressPercentage: Float = 0.0
    var outputFilePath: URL?
    var errorState: ErrorState?
    var cancellationRequested: Bool = false
    init(id: ExportJobID, assetID: ModelID, format: ExportFormat) {
        self.id = id; self.assetID = assetID; self.format = format
    }
}
