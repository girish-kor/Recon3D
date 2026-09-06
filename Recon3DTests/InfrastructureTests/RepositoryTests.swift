import XCTest
@testable import Recon3D

class RepositoryTests: XCTestCase {
    func testListEmpty() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let repo = try FileSystemRepository(rootDir: dir)
        XCTAssertTrue(repo.listModels().isEmpty)
    }
}
