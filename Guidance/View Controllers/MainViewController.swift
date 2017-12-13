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

class MainViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, AddMessageViewControllerDelegate, BottomSheetViewControllerDelegate {

    var isAddingMessage: Bool = false
    var isFetchingMessage: Bool = false
    var showingBottomSheet: Bool = false
    var currentMessage: String = ""

    var messageManager = MessageManager()
    var sceneAnchors = [ARAnchor]()

    var bottomSheetInstance = BottomSheetViewController()

    // MARK: UI Elements
    @IBOutlet var sceneView: SceneLocationView!
    @IBOutlet weak var addModeButton: UIButton!
    @IBOutlet weak var showMapButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        markBottomSheetAsDismissed()

        // Set the view's delegate
        sceneView.delegate = self

        
        sceneView.frame = view.bounds
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene

        guard let currentUserCoordinates = sceneView.locationManager.currentLocation?.coordinate else { print("couldn't get coordinates"); return }
        messageManager.fetchMessage(userCoordinate: currentUserCoordinates, onComplete: {
            print("initial fetch complete")
        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        bottomSheetInstance = BottomSheetViewController.instance()
        bottomSheetInstance.delegate = self

        setupBottomSheet()

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
    
    func enteredMessage(message: String) {
        currentMessage = message

        print(isAddingMessage)

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

    func showBottomSheet(withMessage message: Message) {
        bottomSheetInstance.currentMessage = message
        bottomSheetInstance.refreshBottomView()


        if !showingBottomSheet {
            bottomSheetInstance.displayBottomSheet()
        }
    }

    func markBottomSheetAsDismissed() {
        showingBottomSheet = false
        print("bottom sheet is not showing")
    }

    func setupBottomSheet() {

        self.addChildViewController(bottomSheetInstance)
        self.view.addSubview(bottomSheetInstance.view)
        bottomSheetInstance.didMove(toParentViewController: self)

        let height = view.frame.height
        let width  = view.frame.width

        bottomSheetInstance.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: width, height: height / 2)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let sceneView = self.sceneView else {
            return
        }
        //        guard let currentFrame = sceneView.session.currentFrame else { return }
        guard let touchLocation = touches.first?.location(in: sceneView) else { return }

        if !isAddingMessage {
            if showingBottomSheet {
                print("bottom sheet is showing")
                bottomSheetInstance.closeBottomSheet()
            }

            if let foundMessage = message(at: touchLocation) {
                showBottomSheet(withMessage: foundMessage)
                showingBottomSheet = true
            }
        }

        // Gets the camera's position and places an anchor there
        guard let cameraPosition = getCameraPosition(in: sceneView), isAddingMessage else { return }
        let worldPosition = cameraPosition + getDirection(for: touchLocation, in: sceneView)

        let emptyNode = SCNNode()
        emptyNode.position = worldPosition

        let anchor = ARAnchor(transform: simd_float4x4(emptyNode.transform))
        sceneView.session.add(anchor: anchor)
        sceneAnchors.append(anchor)

    }

    func showFetchedMessages() {

        guard let currentUserCoordinates = sceneView.locationManager.currentLocation?.coordinate else { print("couldn't get coordinates"); return }

        messageManager.clearAllMessages()

        sceneAnchors.removeAll()

        isAddingMessage = false
        isFetchingMessage = true

        messageManager.fetchMessage(userCoordinate: currentUserCoordinates, onComplete: { [unowned self] in

            print("fetch complete")
            for message in self.messageManager.messages {

                print(message.messageContent)
                
                // Skips messages that were already placed
                if message.isPlaced {
                    continue
                }

                self.messageManager.lastPlacedMessage = message

                // Randomly creates anchors around the user
                if let currentFrame = self.sceneView.session.currentFrame {
                    var translation = matrix_identity_float4x4
                    translation.columns.3.x = Float.random(min: -1, max: 1)
                    translation.columns.3.y = Float(message.location.altitude * -0.001)
                    translation.columns.3.z = Float.random(min: -2, max: -1)
                    var transform = simd_mul(currentFrame.camera.transform, translation)

                    let rotation = simd_float4x4(SCNMatrix4MakeRotation(Float.pi / 2, 0, 0, 1))
                    transform = simd_mul(transform, rotation)

                    let anchor = ARAnchor(transform: transform)
                    self.sceneView.session.add(anchor: anchor)
                    self.sceneAnchors.append(anchor)

                    message.transform = SCNMatrix4(transform)
                    self.sceneView.scene.rootNode.addChildNode(message)

                }
            }

            self.isFetchingMessage = false
        })
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

    // This method is called for each new anchor that is added to the scene.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {

        if isFetchingMessage { return }

        if isAddingMessage {
            messageManager.createMessage(withContent: currentMessage, inView: sceneView)
        }

        // Adding a new message
        if let newMessage = messageManager.lastPlacedMessage {
            if isAddingMessage {

            // Upload msg if just added
            messageManager.uploadMessage(message: newMessage)
            self.isAddingMessage = false

            newMessage.isPlaced = true
            print("placed new message", newMessage.messageContent)
            node.addChildNode(newMessage)
            }
        }

    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay

    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        session.run(configuration, options: [.removeExistingAnchors, .resetTracking])
    }

    // needed for modal
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

extension UIViewController {
    class func instance() -> Self {
        let storyboardName = String(describing: self)
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        return storyboard.initialViewController()
    }
}

extension UIStoryboard {
    func initialViewController<T: UIViewController>() -> T {
        return self.instantiateInitialViewController() as! T
    }
}

public extension Float {

    // Returns a random floating point number between 0.0 and 1.0, inclusive.

    public static var random:Float {
        get {
            return Float(arc4random()) / 0xFFFFFFFF
        }
    }
    /*
     Create a random num Float

     - parameter min: Float
     - parameter max: Float

     - returns: Float
     */
    public static func random(min: Float, max: Float) -> Float {
        return Float.random * (max - min) + min
    }
}

