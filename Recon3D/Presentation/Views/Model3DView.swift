import UIKit
import SceneKit

class Model3DView: SCNView {
    func loadMesh(_ mesh: Mesh) {
        let scene = SCNScene()
        // Convert Mesh to SCNGeometry (simplified)
        let geometry = SCNSphere(radius: 0.5)
        let node = SCNNode(geometry: geometry)
        scene.rootNode.addChildNode(node)
        self.scene = scene
        allowsCameraControl = true
    }
}
