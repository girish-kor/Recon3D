import Foundation
import UIKit
class ConfigurationLoader {
    static func loadConfiguration() -> ProcessingConfiguration {
        // Load from local plist and remote
        guard let url = Bundle.main.url(forResource: "config", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return ProcessingConfiguration() // defaults
        }
        // Parse dict into config (simplified)
        var config = ProcessingConfiguration()
        // Apply remote overrides if available
        return config
    }
}

struct SystemCapabilities {
    static func current() -> DeviceCapabilities {
        // Use UIDevice, ProcessInfo, etc.
        return DeviceCapabilities(deviceModel: UIDevice.current.model,
                                  osVersion: UIDevice.current.systemVersion,
                                  hasBackCamera: true,
                                  hasFrontCamera: true,
                                  maxPhotoResolution: (4032, 3024),
                                  maxVideoResolution: (1920, 1080),
                                  supportsDepthAPI: true, // check for LiDAR
                                  supportsAR: true,
                                  supportsMetal: true,
                                  supportsCUDA: false,
                                  cpuCores: ProcessInfo.processInfo.processorCount,
                                  totalMemoryBytes: ProcessInfo.processInfo.physicalMemory,
                                  freeMemoryBytes: ProcessInfo.processInfo.physicalMemory / 2,
                                  totalStorageBytes: 128_000_000_000,
                                  freeStorageBytes: 50_000_000_000,
                                  batteryLevelPercent: 80,
                                  batteryState: .unplugged,
                                  thermalState: .nominal,
                                  isLowPowerModeEnabled: false,
                                  supportedExportFormats: [.usdz, .obj, .gltfBinary])
    }
}
