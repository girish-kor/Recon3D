import Foundation
import SceneKit

class USDZExporter {
    func export(asset: ModelAsset, to url: URL, options: ExportOptions) throws {
        let mesh = asset.mesh
        guard !mesh.vertices.isEmpty else {
            throw NSError(domain: "USDZExporter", code: 801, userInfo: [NSLocalizedDescriptionKey: "Empty mesh"])
        }
        
        let scnVertices: [SCNVector3] = mesh.vertices.map { SCNVector3($0.x, $0.y, $0.z) }
        let indices: [Int32] = mesh.indices.map { Int32($0) }
        
        var sources: [SCNGeometrySource] = [SCNGeometrySource(vertices: scnVertices)]
        
        if options.includeNormals, let normals = mesh.normals {
            sources.append(SCNGeometrySource(normals: normals.map { SCNVector3($0.x, $0.y, $0.z) }))
        }
        
        let element = SCNGeometryElement(indices: indices, primitiveType: .triangles)
        let geometry = SCNGeometry(sources: sources, elements: [element])
        
        let node = SCNNode(geometry: geometry)
        let scene = SCNScene()
        scene.rootNode.addChildNode(node)
        
        try scene.write(to: url, options: [:], delegate: nil, progressHandler: nil)
    }
}
