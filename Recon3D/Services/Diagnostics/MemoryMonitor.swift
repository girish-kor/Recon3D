import Foundation

class MemoryMonitor {
    func currentUsage() -> UInt64 {
        return ProcessInfo.processInfo.physicalMemory / 2
    }
    func checkWarning() -> MemoryWarningLevel {
        return .normal
    }
}
