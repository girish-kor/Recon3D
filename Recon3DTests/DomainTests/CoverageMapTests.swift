import XCTest
@testable import Recon3D

class CoverageMapTests: XCTestCase {
    func testSufficientCoverage() {
        var map = CoverageMap()
        for az in 0..<24 {
            for el in 0..<12 {
                let contrib = CoverageContribution(azimuthDeg: Float(az*10), elevationDeg: Float(el*10-90), binIndexAz: UInt8(az), binIndexEl: UInt8(el))
                map.update(with: contrib, confidence: 0.9)
            }
        }
        XCTAssertTrue(map.isSufficient(requiredAzimuthBins: 24, requiredElevationBins: 12, minFramesPerBin: 1))
    }
}
