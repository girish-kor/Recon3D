import Foundation

struct ProcessingConfiguration: Codable {
    var capture: CaptureConfig
    var reconstruction: ReconstructionConfig
    var postProcess: PostProcessConfig
    var system: SystemResourceConfig
}

struct CaptureConfig: Codable {
    var preset: CaptureQualityPreset = .medium
    var resolutionWidth: UInt16 = 1920
    var resolutionHeight: UInt16 = 1080
    var targetFPS: UInt8 = 30
    var maxFramesToCapture: UInt16 = 300
    var minFramesRequired: UInt16 = 50
    var focusMode: FocusMode = .continuous
    var exposureMode: ExposureMode = .continuous
    var exposureTarget: Float = 0.5
    var motionBlurThreshold: Float = 15.0
    var sharpnessThreshold: Float = 30.0
    var luminanceMin: Float = 0.05
    var luminanceMax: Float = 0.95
    var contrastThreshold: Float = 15.0
    var coverageRequiredAzimuthBins: UInt8 = 24
    var coverageRequiredElevationBins: UInt8 = 12
    var coverageMinFramesPerBin: UInt8 = 2
    var enableDepthSensorIfAvailable: Bool = true
    var maxRetriesOnTrackingLoss: UInt8 = 3
    var autoStop: Bool = true
}

struct ReconstructionConfig: Codable {
    var processingMode: ProcessingMode = .localBalanced
    var meshDensity: MeshDensityPreset = .medium
    var textureResolution: TextureResolutionPreset = ._2048
    var featureDetector: FeatureDetector = .orb
    var featureMatcher: FeatureMatcher = .flann
    var depthEstimationMethod: DepthEstimationMethod = .monocularCNN
    var volumetricResolution: UInt16 = 256
    var holeFillingMaxHoleSize: UInt16 = 50
    var denoisingStrength: Float = 0.5
    var smoothingIterations: UInt8 = 5
    var decimationTargetFraction: Float = 0.3
    var uvAtlasResolution: UInt16 = 2048
    var textureBlendingMode: TextureBlendingMode = .weightedPose
    var texturePaddingPixels: UInt16 = 2
    var enableMaterialEstimation: Bool = true
    var qualityMinOverallScore: Float = 75.0
    var qualityMinVertexCount: UInt32 = 500
    var qualityMaxVertexCount: UInt32 = 100000
    var normalConsistencyThreshold: Float = 0.9
    var enableCheckpointing: Bool = true
}

struct PostProcessConfig: Codable {
    var enableHoleFilling: Bool = true
    var enableDenoising: Bool = true
    var enableSmoothing: Bool = true
    var enableTopologyCorrection: Bool = true
    var enableDecimation: Bool = true
    var enableNormalGen: Bool = true
    var enableUVGen: Bool = true
    var enableTextureRecon: Bool = true
    var enableMaterialGen: Bool = true
}

struct SystemResourceConfig: Codable {
    var maxMemoryUsageBytes: UInt64 = 1_073_741_824 // 1GB
    var maxTempStorageBytes: UInt64 = 5_368_709_120 // 5GB
    var minAvailableDiskMB: UInt64 = 500
    var cpuThreadPoolSize: UInt8 = 4
    var gpuComputeUnits: UInt8 = 1
    var checkpointIntervalSeconds: UInt16 = 30
    var backgroundExecutionTimeoutSeconds: UInt16 = 600
    var thermalThrottleThreshold: Float = 80.0 // Celsius
}
