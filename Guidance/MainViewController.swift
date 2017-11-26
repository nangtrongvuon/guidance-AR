//
//  ViewController.swift
//  Guidance
//
//  Created by Dzũng Lê on 28/10/2017.
//  Copyright © 2017 Dzũng Lê. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import CoreLocation

class MainViewController: UIViewController, ARSCNViewDelegate, AddMessageViewControllerDelegate {
    
    var isAddingMessage: Bool = false
    var currentMessage: String = ""
    
    var messageManager = MessageManager()
    
    // MARK: UI Elements
    @IBOutlet var sceneView: SceneLocationView!
    @IBOutlet weak var addModeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
//        sceneView = SceneLocationView()
        sceneView.frame = view.bounds
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
        
//        sceneView.addLocationNodeForCurrentPosition(locationNode: Message(messageContent: "the quick brown fox jumps over the lazy dog"))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    // MARK: - ARSCNViewDelegate
    
    func enteredMessage(message: String) {
        currentMessage = message
        print(currentMessage)
        self.isAddingMessage = true
    }

    func message(at point: CGPoint) -> Message? {
        let hitTestResults = sceneView.hitTest(point)

        if let nodeHit = hitTestResults.first?.node {
            let foundMessage = nodeHit.parent as? Message
            return foundMessage
        } else {
            return nil
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sceneView = self.sceneView else {
            return
        }
        
//        guard let currentFrame = sceneView.session.currentFrame else { return }
        guard let touchLocation = touches.first?.location(in: sceneView) else { return }

        if !isAddingMessage {
            if let foundMessage = message(at: touchLocation) {
                messageManager.deleteMessage(messageToDelete: foundMessage)
            }
        }

        guard let cameraPosition = getCameraPosition(in: sceneView), isAddingMessage else { return }
        
        let worldPosition = cameraPosition + getDirection(for: touchLocation, in: sceneView)
        
        let emptyNode = SCNNode()
        emptyNode.position = worldPosition

        let anchor = ARAnchor(transform: simd_float4x4(emptyNode.transform))
        sceneView.session.add(anchor: anchor)
        
        let newMessage = messageManager.createMessage(atPoint: worldPosition, withContent: currentMessage, inView: sceneView)
        
        sceneView.scene.rootNode.addChildNode(newMessage)
        
        self.isAddingMessage = false
        
    }
    
    
    // We use this to determine the location of a tap. In the 3D world, we would like this to refer to a direction.
    func getDirection(for point: CGPoint, in view: SCNView) -> SCNVector3 {
        let farPoint = view.unprojectPoint(SCNVector3(Float(point.x), Float(point.y), 1))
        let nearPoint = view.unprojectPoint(SCNVector3(Float(point.x), Float(point.y), 0))
        
        let direction = (farPoint - nearPoint).normalized()
        
        //        direction.z *= 2
        
        return direction
    }
    
    func getCameraPosition(in view: ARSCNView) -> SCNVector3? {
        guard let lastFrame = view.session.currentFrame else {
            return nil
        }
        
        let position = lastFrame.camera.transform * float4(x: 0, y:  0, z: 0, w: 1)
        let camera: SCNVector3 = SCNVector3(position.x, position.y, position.z)
        
        return camera
    }
    
    func center(node: SCNNode) {
        let (min, max) = node.boundingBox
        
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
    }
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

extension UIViewController {
    class func instance() -> Self {
        let storyboardName = String(describing: self)
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        return storyboard.initialViewController()
    }
}

