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

class MainViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate, AddMessageViewControllerDelegate, BottomSheetViewControllerDelegate, MessageManagerDelegate {


    // MARK: Queues
    let serialQueue = DispatchQueue(label: "com.nangtrongvuon.Guidance.serialSceneKitQueue")

    // MARK: Variables
    var messageManager: MessageManager!
    var statusManager: StatusManager!
    var isAddingMessage: Bool = false
    var isFetchingMessage: Bool = false
    var showingBottomSheet: Bool = false
    var currentMessage: String = ""

    var bottomSheetInstance = BottomSheetViewController()

    // MARK: UI Elements
    @IBOutlet var sceneView: SceneLocationView!
    @IBOutlet weak var addModeButton: UIButton!
    @IBOutlet weak var showMapButton: UIButton!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var messagePanel: UIVisualEffectView!
    @IBOutlet weak var messageLabel: UILabel!
    var spinner: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        markBottomSheetAsDismissed()

        // Set the view's delegate
        sceneView.delegate = self
        sceneView.frame = view.bounds
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = false

        messageManager = MessageManager(updateQueue: serialQueue)
        messageManager.delegate = self
        // Create a new scene
        let scene = SCNScene()
        
        // Set the scene to the view
        sceneView.scene = scene

        guard let currentUserCoordinates = sceneView.locationManager.currentLocation?.coordinate else { print("couldn't get coordinates"); return }
        messageManager.fetchMessage(range: 25, userCoordinate: currentUserCoordinates, onComplete: {
            print("initial fetch complete")
        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        bottomSheetInstance = BottomSheetViewController.instance()
        bottomSheetInstance.delegate = self

        setupUIElements()

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
    
    func addMessageViewController(didFinishAddingMessage message: String) {
        currentMessage = message
        isAddingMessage = true
        statusManager.showMessage("Tap anywhere on the screen to add a new message.", autoHide: true)
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

    func setupUIElements() {

        self.addChildViewController(bottomSheetInstance)
        self.view.addSubview(bottomSheetInstance.view)
        bottomSheetInstance.didMove(toParentViewController: self)

        let height = view.frame.height
        let width = view.frame.width

        bottomSheetInstance.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: width, height: height / 2)

        statusManager = StatusManager(viewController: self)

        // Set appearance of message output panel
        messagePanel.layer.cornerRadius = 3.0
        messagePanel.clipsToBounds = true
        messagePanel.isHidden = true
        messageLabel.text = ""

    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

        guard let touchLocation = touches.first?.location(in: sceneView) else { return }

        // TODO: Remove this part from view controller
        if !isAddingMessage {
            if showingBottomSheet {
                print("bottom sheet is showing")
                bottomSheetInstance.closeBottomSheet()
            }

            if let foundMessage = message(at: touchLocation) {
                showBottomSheet(withMessage: foundMessage)
                showingBottomSheet = true
            }
        } else {
            // Adding a new message
            messageManager.reactToTouchesBegan(touches, with: currentMessage, with: event, in: sceneView)
            isAddingMessage = false
        }
    }

    func messageManager(_ manager: MessageManager, didFinishFetchingMessages messages: [Message]) {
        statusManager.showMessage("Fetched \(messages.count) messages.", autoHide: true)
    }

//    func initiateMessageFetch() {
//        guard let currentUserCoordinates = sceneView.locationManager.currentLocation?.coordinate else { print("couldn't get coordinates"); return }
//
//        isAddingMessage = false
//        isFetchingMessage = true
//
//        // Fetch messages in background
//        self.messageManager.fetchMessage(range: 25, userCoordinate: currentUserCoordinates, onComplete: { [unowned self] in
//            self.isFetchingMessage = false
//            print("finished fetching")
//
//            self.statusManager.showMessage("Found \(self.messageManager.messages.count) messages.", autoHide: true)
//            self.messageManager.displayFetchedMessages(inView: self.sceneView)
//        })
//    }

    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusManager.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)

        switch camera.trackingState {
        case .notAvailable:
            fallthrough
        case .limited:
            statusManager.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusManager.cancelScheduledMessage(forType: .trackingState)
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        guard let arError = error as? ARError else { return }

        let nsError = error as NSError
        var sessionErrorMsg = "\(nsError.localizedDescription) \(nsError.localizedFailureReason ?? "")"
        if let recoveryOptions = nsError.localizedRecoveryOptions {
            for option in recoveryOptions {
                sessionErrorMsg.append("\(option).")
            }
        }

        let isRecoverable = (arError.code == .worldTrackingFailed)
        if isRecoverable {
            sessionErrorMsg += "\nYou can try resetting the session or quit the application."
        } else {
            sessionErrorMsg += "\nThis is an unrecoverable error that requires to quit the application."
        }

        statusManager.showMessage(sessionErrorMsg)
    }

    func sessionWasInterrupted(_ session: ARSession) {
        statusManager.blurBackground()
        statusManager.showMessage("SESSION HAS BEEN INTERRUPTED AND WILL RESUME")
    }

    func sessionInterruptionEnded(_ session: ARSession) {
        statusManager.unblurBackground()
        let configuration = ARWorldTrackingConfiguration()
        session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        statusManager.showMessage("RESETTING SESSION")
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

