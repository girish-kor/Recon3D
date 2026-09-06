import Foundation

enum SessionStatus: String, Codable {
    case idle, initializing, active, paused, stopping, terminated, error, completed
}
enum JobStatus: String, Codable {
    case pending, running, paused, checkpointing, completed, failed, cancelled
}
enum ReconstructionStage: Int, Codable, CaseIterable {
    case preprocessing = 0, featureExtraction, featureMatching, poseEstimation, depthEstimation,
         pointcloudGeneration, pointcloudFilter, volumetricRecon, meshGeneration, holeFilling,
         denoising, smoothing, topologyCorrection, decimation, normalComputation, uvParameterization,
         textureReconstruction, materialGeneration, validation, qualityScoring, optimization, packaging
}
enum ErrorCode: Int, Codable {
    // Permission
    case permissionCameraDenied = 100, permissionStorageDenied = 101, permissionMicrophoneDenied = 102
    // Capability
    case capUnsupportedDevice = 200, capInsufficientMemory = 201, capInsufficientStorage = 202,
         capThermalThrottle = 203, capLowBattery = 204, capNoCamera = 205
    // Camera/Session
    case camInitFail = 300, camStreamFail = 301, camFocusFail = 302, camExposureFail = 303,
         camTrackingLost = 304, camPoseInvalid = 305
    // Frame Quality
    case frameMotionBlur = 400, frameOutOfFocus = 401, frameOverexposed = 402, frameUnderexposed = 403,
         frameLowContrast = 404, frameCorrupted = 405
    // Coverage
    case covInsufficientCoverage = 500, covMissingAzimuth = 501, covMissingElevation = 502
    // Reconstruction
    case reconAlignmentFail = 600, reconFeatureMatchFail = 601, reconPoseDrift = 602,
         reconDepthFail = 603, reconPointcloudEmpty = 604, reconMeshInvalid = 605,
         reconTextureProjectionFail = 606, reconIntermediateCorrupt = 607
    // Persistence
    case ioWriteFail = 700, ioReadFail = 701, ioSpaceExhausted = 702, ioFileCorrupt = 703
    // Export
    case exportFormatUnsupported = 800, exportTranscodingFail = 801, exportCancelled = 802
    // System
    case sysOutOfMemory = 900, sysThreadDeadlock = 901, sysAppTerminated = 902
}
enum ExportFormat: String, Codable, CaseIterable {
    case usdz, obj, gltfBinary, gltfASCII, stl, ply
}
enum ProcessingMode: String, Codable {
    case localLowPower, localBalanced, localHighQuality, cloudAssisted
}
enum CaptureQualityPreset: String, Codable {
    case low, medium, high, ultra
}
enum MeshDensityPreset: String, Codable {
    case low = "500", medium = "2000", high = "8000", ultra = "25000"
    var vertexTarget: UInt32 {
        switch self {
        case .low: return 500
        case .medium: return 2000
        case .high: return 8000
        case .ultra: return 25000
        }
    }
}
enum TextureResolutionPreset: String, Codable {
    case _512 = "512", _1024 = "1024", _2048 = "2048", _4096 = "4096"
    var intValue: UInt16 {
        switch self {
        case ._512: return 512
        case ._1024: return 1024
        case ._2048: return 2048
        case ._4096: return 4096
        }
    }
}
enum FocusMode: String, Codable { case auto, locked, continuous }
enum ExposureMode: String, Codable { case auto, locked, continuous }
enum FeatureDetector: String, Codable { case sift, surf, orb, akaze, superpoint }
enum FeatureMatcher: String, Codable { case flann, bruteForce, superglue }
enum DepthEstimationMethod: String, Codable { case monocularCNN, stereoMVS, lidarFusion }
enum TextureBlendingMode: String, Codable { case average, median, weightedPose, seamLevel }
enum MaterialProperty: String, Codable { case baseColor, metallic, roughness, normal, emissive }
enum MeshValidity: String, Codable { case valid, degenerate, nonManifold, holes, selfIntersections }
enum RecoverySuggestion: String, Codable { case retry, addFrames, changeSettings, freeSpace, restartApp, unrecoverable }
enum QualityVerdict: String, Codable { case pass, rejectMotion, rejectFocus, rejectExposure, rejectContrast, rejectCorrupt }
enum BatteryState: String, Codable { case unknown, unplugged, charging, full }
enum ThermalState: String, Codable { case nominal, fair, serious, critical }
enum MemoryWarningLevel: String { case normal, warning, critical }
