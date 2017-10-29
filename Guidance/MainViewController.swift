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

class MainViewController: UIViewController, ARSCNViewDelegate {
    
    var isAddingMessage: Bool = false
    var currentMessage: String = ""
    
    // MARK: UI Elements
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var addModeButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
//        sceneView.debugOptions = [.showBoundingBoxes]
        
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
    
    
    // Override to create and configure nodes for anchors added to the view's session.
    //    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
    //        let node = SCNNode()
    //
    //        node.geometry = SCNSphere(radius: 0.005)
    //
    //
    //        return node
    //    }
    
    func placeMessage(at point: SCNVector3, withMessage message: String) -> SCNNode {
        
        let placedNode = SCNNode()
        
        let message = SCNText(string: message, extrusionDepth: 0)
        message.containerFrame = CGRect(origin: .zero, size: CGSize(width: 100.0, height: 500.0))
        message.isWrapped = true
        
        message.font = UIFont(name: "San Francisco", size: 16)
        message.flatness = 1
        let messageNode = SCNNode(geometry: message)
        
        center(node: messageNode)
        
        let (minVec, maxVec) = messageNode.boundingBox
        
        let borderWidth = CGFloat(maxVec.x - minVec.x) + 10
        let borderHeight = CGFloat(maxVec.y - minVec.y) + 10
        
        let backgroundBox = SCNPlane(width: borderWidth, height: borderHeight)
        backgroundBox.cornerRadius = borderWidth / 10
        backgroundBox.firstMaterial!.diffuse.contents = UIColor.blue.withAlphaComponent(1)
        backgroundBox.firstMaterial!.isDoubleSided = true
        let boxNode = SCNNode(geometry: backgroundBox)
        
        // Make text face camera.
        guard let sceneViewOrientation = sceneView.pointOfView?.orientation else { return SCNNode() }
        
        placedNode.orientation = sceneViewOrientation
        
        placedNode.addChildNode(boxNode)
        placedNode.addChildNode(messageNode)
        
        placedNode.position = point
        placedNode.scale = SCNVector3(0.005, 0.005, 0.005)
        
        messageNode.position.z += 0.02
        
        return placedNode
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sceneView = self.sceneView, isAddingMessage else {
            return
        }
        
//        guard let currentFrame = sceneView.session.currentFrame else { return }
        guard let touchLocation = touches.first?.location(in: sceneView) else { return }
        guard let cameraPosition = getCameraPosition(in: sceneView) else { return }
        
        let worldPosition = cameraPosition + getDirection(for: touchLocation, in: sceneView)
        
        sceneView.scene.rootNode.addChildNode(placeMessage(at: worldPosition, withMessage: currentMessage))
        
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

