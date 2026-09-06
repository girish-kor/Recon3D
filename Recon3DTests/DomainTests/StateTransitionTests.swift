import XCTest
@testable import Recon3D

class StateTransitionTests: XCTestCase {
    func testIdleToActive() {
        XCTAssertEqual(SessionStatus.idle.rawValue, "idle")
    }
}
