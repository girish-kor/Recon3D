import Foundation

extension Date {
    var nanoseconds: UInt64 {
        return UInt64(self.timeIntervalSince1970 * 1_000_000_000)
    }
}
