import Foundation

struct DeviceCapabilities: Codable {
    var deviceModel: String
    var osVersion: String
    var hasBackCamera: Bool
    var hasFrontCamera: Bool
    var maxPhotoResolution: (width: UInt16, height: UInt16)
    var maxVideoResolution: (width: UInt16, height: UInt16)
    var supportsDepthAPI: Bool
    var supportsAR: Bool
    var supportsMetal: Bool
    var supportsCUDA: Bool = false
    var cpuCores: UInt8
    var totalMemoryBytes: UInt64
    var freeMemoryBytes: UInt64
    var totalStorageBytes: UInt64
    var freeStorageBytes: UInt64
    var batteryLevelPercent: UInt8
    var batteryState: BatteryState
    var thermalState: ThermalState
    var isLowPowerModeEnabled: Bool
    var supportedExportFormats: [ExportFormat]
}
