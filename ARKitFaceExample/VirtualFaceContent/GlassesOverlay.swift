/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An `SCNNode` subclass demonstrating how to configure overlay content.
*/

import ARKit
import SceneKit

class GlassesOverlay: SCNNode, VirtualFaceContent {
    
    let occlusionNode: SCNNode
    
    /// - Tag: OcclusionMaterial
    init(geometry: ARSCNFaceGeometry) {

        /*
         Write depth but not color and render before other objects.
         This causes the geometry to occlude other SceneKit content
         while showing the camera view beneath, creating the illusion
         that real-world objects are obscuring virtual 3D objects.
         */
        geometry.firstMaterial!.colorBufferWriteMask = []
        occlusionNode = SCNNode(geometry: geometry)
        occlusionNode.renderingOrder = -1

        super.init()

        addChildNode(occlusionNode)
        
        // Add 3D content positioned as "glasses".
        let faceOverlayContent = loadedContentForAsset(named: "overlayModel")
        addChildNode(faceOverlayContent)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) has not been implemented")
    }
    
    // MARK: VirtualFaceContent
    
    func update(withFaceAnchor anchor: ARFaceAnchor) {
        let faceGeometry = occlusionNode.geometry as! ARSCNFaceGeometry
        faceGeometry.update(from: anchor.geometry)
    }
}
