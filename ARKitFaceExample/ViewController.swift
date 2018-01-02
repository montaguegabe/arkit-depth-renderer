/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, ARSessionDelegate {
    
    // MARK: Outlets

    @IBOutlet var sceneView: ARSCNView!

    @IBOutlet weak var blurView: UIVisualEffectView!

    lazy var statusViewController: StatusViewController = {
        return childViewControllers.lazy.flatMap({ $0 as? StatusViewController }).first!
    }()

    // MARK: Properties

    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }

    var nodeForContentType = [VirtualContentType: VirtualFaceNode]()
    
    let contentUpdater = VirtualContentUpdater()
    
    var selectedVirtualContent: VirtualContentType = .overlayModel {
        didSet {
            // Set the selected content based on the content type.
            contentUpdater.virtualFaceNode = nodeForContentType[selectedVirtualContent]
        }
    }
    
    var context = CIContext()
    let backgroundTransform = SCNMatrix4Scale(SCNMatrix4MakeRotation(Float.pi / 2.0, 0, 0, 1), -1, 1, 1)
    
    var num : CGFloat = 0
    
    // Woah this line of code is incredibly cool. If it doesn't work then your Xcode is probably not up to date.
    let gradientImage = CIImage(cgImage: #imageLiteral(resourceName: "Gradient.png").cgImage!)
    
    // MARK: - View Controller Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = contentUpdater
        sceneView.session.delegate = self
        sceneView.automaticallyUpdatesLighting = true
        
        // Display black background until depth is available
        sceneView.scene.background.contents = UIColor.black
        
        createFaceGeometry()

        // Set the initial face content, if any.
        contentUpdater.virtualFaceNode = nodeForContentType[selectedVirtualContent]

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        /*
            AR experiences typically involve moving the device without
            touch input for some time, so prevent auto screen dimming.
        */
        UIApplication.shared.isIdleTimerDisabled = true
        
        resetTracking()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        session.pause()
    }
    
    // MARK: - Setup
    
    /// - Tag: CreateARSCNFaceGeometry
    func createFaceGeometry() {
        // This relies on the earlier check of `ARFaceTrackingConfiguration.isSupported`.
        let device = sceneView.device!
        let maskGeometry = ARSCNFaceGeometry(device: device)!
        let glassesGeometry = ARSCNFaceGeometry(device: device)!
        
        nodeForContentType = [
            .faceGeometry: Mask(geometry: maskGeometry),
            .overlayModel: GlassesOverlay(geometry: glassesGeometry),
            .blendShapeModel: RobotHead()
        ]
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        
        let depthData = frame.capturedDepthData
        if depthData != nil {
            
            // Render depth data to background texture (not quite as fast as using Metal textures)
            let depthBuffer : CVPixelBuffer = depthData!.depthDataMap
            
            let width = CVPixelBufferGetWidth(depthBuffer)
            let height = CVPixelBufferGetHeight(depthBuffer)
            let frameWidth = sceneView.frame.size.width
            let frameHeight = sceneView.frame.size.height
            let depthImage = CIImage(cvImageBuffer: depthBuffer)
            let targetSize = CGSize(width: frameWidth, height: frameHeight)
            

            var normalizeTransform = CGAffineTransform(a: 1.0 / CGFloat(width), b: 0, c: 0, d: -1.0 / CGFloat(height), tx: 0, ty: 1.0)
            var correctTransform = frame.displayTransform(for: UIInterfaceOrientation.portrait, viewportSize: targetSize) //.inverted()
            var rescaleTransform = CGAffineTransform(a: CGFloat(frameWidth), b: 0, c: 0, d: CGFloat(frameHeight), tx: 0, ty: 0)
            var transform = normalizeTransform.concatenating(correctTransform).concatenating(rescaleTransform)
            let depthImageTransformed = depthImage.transformed(by: transform)
            
            // Do color map
            let filter = CIFilter(name: "CIColorMap")!
            filter.setValue(gradientImage, forKey: kCIInputGradientImageKey)
            filter.setValue(depthImageTransformed, forKey: kCIInputImageKey)
            let mappedImage = filter.outputImage!
            

            let renderedBackground : CGImage = context.createCGImage(mappedImage, from: CGRect(x: 0, y: 0, width: CGFloat(frameWidth), height: CGFloat(frameHeight)))!
            let texture = SKTexture(cgImage: renderedBackground)
            
            sceneView.scene.background.contents = texture
            sceneView.scene.background.contentsTransform = SCNMatrix4Identity
            
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        let errorMessage = messages.flatMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }

    func sessionWasInterrupted(_ session: ARSession) {
        blurView.isHidden = false
        statusViewController.showMessage("""
        SESSION INTERRUPTED
        The session will be reset after the interruption has ended.
        """, autoHide: false)
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        blurView.isHidden = true
        
        DispatchQueue.main.async {
            self.resetTracking()
        }
    }
    
    /// - Tag: ARFaceTrackingSetup
    func resetTracking() {
        statusViewController.showMessage("STARTING A NEW SESSION")
        
        guard ARFaceTrackingConfiguration.isSupported else { return }
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    // MARK: - Interface Actions

    /// - Tag: restartExperience
    func restartExperience() {
        // Disable Restart button for a while in order to give the session enough time to restart.
        statusViewController.isRestartExperienceButtonEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.statusViewController.isRestartExperienceButtonEnabled = true
        }

        resetTracking()
    }
    
    // MARK: - Error handling
    
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        present(alertController, animated: true, completion: nil)
    }
}

extension ViewController: UIPopoverPresentationControllerDelegate {

    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        /*
         Popover segues should not adapt to fullscreen on iPhone, so that
         the AR session's view controller stays visible and active.
        */
        return .none
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        /*
         All segues in this app are popovers even on iPhone. Configure their popover
         origin accordingly.
        */
        guard let popoverController = segue.destination.popoverPresentationController, let button = sender as? UIButton else { return }
        popoverController.delegate = self
        popoverController.sourceRect = button.bounds

        // Set up the view controller embedded in the popover.
        let contentSelectionController = popoverController.presentedViewController as! ContentSelectionController

        // Set the initially selected virtual content.
        contentSelectionController.selectedVirtualContent = selectedVirtualContent

        // Update our view controller's selected virtual content when the selection changes.
        contentSelectionController.selectionHandler = { [unowned self] newSelectedVirtualContent in
            self.selectedVirtualContent = newSelectedVirtualContent
        }
    }
}
