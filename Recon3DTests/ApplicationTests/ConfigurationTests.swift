import XCTest
@testable import Recon3D

class ConfigurationTests: XCTestCase {
    func testDefaultConfig() {
        let config = ProcessingConfiguration()
        XCTAssertEqual(config.capture.preset, .medium)
    }
}
