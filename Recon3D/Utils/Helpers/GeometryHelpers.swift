import Foundation
import simd

func lookDirection(from pose: CameraPose) -> simd_float3 {
    return simd_normalize(pose.rotation * simd_float3(0, 0, -1))
}
