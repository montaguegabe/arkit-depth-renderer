/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An `ARSCNViewDelegate` which addes and updates the virtual face content in response to the ARFaceTracking session.
*/

import SceneKit
import ARKit

class VirtualContentUpdater: NSObject, ARSCNViewDelegate {
    
    // MARK: Configuration Properties
    
    /**
     Developer setting to display a 3D coordinate system centered on the tracked face.
     See `axesNode`.
     - Tag: ShowCoordinateOrigin
     */
    let showsCoordinateOrigin = false
    
    // MARK: Properties
    
    /// The virtual content that should be displayed and updated.
    var virtualFaceNode: VirtualFaceNode? {
        didSet {
            setupFaceNodeContent()
        }
    }
    
    /**
     A reference to the node that was added by ARKit in `renderer(_:didAdd:for:)`.
     - Tag: FaceNode
     */
    private var faceNode: SCNNode?
    
    /// A 3D coordinate system node.
    private let axesNode = loadedContentForAsset(named: "coordinateOrigin")
    
    private let serialQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitFaceExample.serialSceneKitQueue")
    
    /// - Tag: FaceContentSetup
    private func setupFaceNodeContent() {
        guard let node = faceNode else { return }
        
        // Remove all the current children.
        for child in node.childNodes {
            child.removeFromParentNode()
        }
        
        if let content = virtualFaceNode {
            node.addChildNode(content)
        }
        
        if showsCoordinateOrigin {
            node.addChildNode(axesNode)
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
    /// - Tag: ARNodeTracking
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Hold onto the `faceNode` so that the session does not need to be restarted when switching masks.
        faceNode = node
        serialQueue.async {
            self.setupFaceNodeContent()
        }
    }
    
    /// - Tag: ARFaceGeometryUpdate
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        
        virtualFaceNode?.update(withFaceAnchor: faceAnchor)
    }
}
