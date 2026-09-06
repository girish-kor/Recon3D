import simd

extension simd_float3x3 {
    static var identity: simd_float3x3 {
        return matrix_identity_float3x3
    }
}
