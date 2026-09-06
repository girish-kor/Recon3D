import Foundation
import UIKit

class BatteryMonitor {
    func level() -> UInt8 {
        UIDevice.current.isBatteryMonitoringEnabled = true
        return UInt8(UIDevice.current.batteryLevel * 100)
    }
    func state() -> BatteryState {
        switch UIDevice.current.batteryState {
        case .charging: return .charging
        case .full: return .full
        case .unplugged: return .unplugged
        default: return .unknown
        }
    }
}
