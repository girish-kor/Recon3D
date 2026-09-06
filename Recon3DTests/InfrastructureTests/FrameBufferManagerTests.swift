import XCTest
@testable import Recon3D

class FrameBufferManagerTests: XCTestCase {
    func testAddAndCapacity() {
        let manager = RingBufferFrameManager(capacity: 5)
        XCTAssertEqual(manager.size, 0)
    }
}
