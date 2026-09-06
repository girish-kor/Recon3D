import Foundation
import simd

class OBJExporter {
    func export(asset: ModelAsset, to url: URL, options: ExportOptions) throws {
        let mesh = asset.mesh
        var output = "# Recon3D OBJ Export\n"
        output += "# Vertices: \(mesh.vertices.count)\n"
        
        for v in mesh.vertices {
            output += "v \(v.x) \(v.y) \(v.z)\n"
        }
        
        if options.includeNormals, let normals = mesh.normals {
            for n in normals {
                output += "vn \(n.x) \(n.y) \(n.z)\n"
            }
        }
        
        if options.includeUVs, let uvs = mesh.uvs {
            for uv in uvs {
                output += "vt \(uv.x) \(uv.y)\n"
            }
        }
        
        // Faces (1-based indices)
        let hasNormals = options.includeNormals && mesh.normals != nil
        let hasUVs = options.includeUVs && mesh.uvs != nil
        for i in stride(from: 0, to: mesh.indices.count, by: 3) {
            let i1 = mesh.indices[i] + 1
            let i2 = mesh.indices[i+1] + 1
            let i3 = mesh.indices[i+2] + 1
            if hasNormals && hasUVs {
                output += "f \(i1)/\(i1)/\(i1) \(i2)/\(i2)/\(i2) \(i3)/\(i3)/\(i3)\n"
            } else if hasNormals {
                output += "f \(i1)//\(i1) \(i2)//\(i2) \(i3)//\(i3)\n"
            } else if hasUVs {
                output += "f \(i1)/\(i1) \(i2)/\(i2) \(i3)/\(i3)\n"
            } else {
                output += "f \(i1) \(i2) \(i3)\n"
            }
        }
        
        try output.write(to: url, atomically: true, encoding: .utf8)
    }
}
