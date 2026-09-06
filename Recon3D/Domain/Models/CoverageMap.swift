import Foundation

struct CoverageMap {
    let azimuthBins: UInt8 = 36
    let elevationBins: UInt8 = 18
    private(set) var occupancy: [[Bool]] = Array(repeating: Array(repeating: false, count: 18), count: 36)
    private(set) var frameCountPerBin: [[UInt16]] = Array(repeating: Array(repeating: 0, count: 18), count: 36)
    private(set) var confidencePerBin: [[Float]] = Array(repeating: Array(repeating: 0.0, count: 18), count: 36)
    
    mutating func update(with contribution: CoverageContribution, confidence: Float) {
        let az = Int(contribution.binIndexAz)
        let el = Int(contribution.binIndexEl)
        guard az < azimuthBins && el < elevationBins else { return }
        occupancy[az][el] = true
        frameCountPerBin[az][el] += 1
        let old = confidencePerBin[az][el]
        let n = Float(frameCountPerBin[az][el])
        confidencePerBin[az][el] = (old * (n - 1) + confidence) / n
    }
    
    func isSufficient(requiredAzimuthBins: UInt8, requiredElevationBins: UInt8, minFramesPerBin: UInt8) -> Bool {
        var azCount = 0
        for az in 0..<Int(azimuthBins) {
            var any = false
            for el in 0..<Int(elevationBins) {
                if occupancy[az][el] && frameCountPerBin[az][el] >= minFramesPerBin {
                    any = true
                }
            }
            if any { azCount += 1 }
        }
        var elCount = 0
        for el in 0..<Int(elevationBins) {
            var any = false
            for az in 0..<Int(azimuthBins) {
                if occupancy[az][el] && frameCountPerBin[az][el] >= minFramesPerBin {
                    any = true
                }
            }
            if any { elCount += 1 }
        }
        return azCount >= requiredAzimuthBins && elCount >= requiredElevationBins
    }
}
