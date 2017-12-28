//
//  MessageManager.swift
//  Guidance
//
//  Created by Dzũng Lê on 30/10/2017.
//  Copyright © 2017 Dzũng Lê. All rights reserved.
//

import Foundation
import CoreLocation
import ARKit
import SceneKit

protocol MessageManagerDelegate: class {
    func messageManager(_ manager: MessageManager, didFinishFetchingMessages: [Message])
}

class MessageManager {
    struct Location: Codable {
        let lat, lon, altitude: Double
    }
    struct StructNewMessage: Codable {
        let message, color: String
        let location: Location
        //        let posterId: Int
        
    }

    var messages = [Message]()
    let locationManager = LocationManager()

    var lastPlacedMessage: Message?
    var fetchTimer: Timer?

    var updateQueue: DispatchQueue

    init(updateQueue: DispatchQueue) {
        self.updateQueue = updateQueue
    }

    // TODO: Implement update queue for messages

    func createMessage(withContent content: String, inView view: ARSCNView)  {
        guard let currentUserLocation = locationManager.currentLocation else { return }
        let newMessage = Message(messageContent: content, location: currentUserLocation)

        if let currentCameraOrientation = view.pointOfView?.orientation {
            newMessage.orientation = currentCameraOrientation
            messages.append(newMessage)
            lastPlacedMessage = newMessage
        }
    }
    
    func createMessage(atPoint point: SCNVector3, withContent content: String, inView view: ARSCNView)  {
        guard let currentUserLocation = locationManager.currentLocation else { return }

        let newMessage = Message(messageContent: content, location: currentUserLocation, point: point)

        if let currentCameraOrientation = view.pointOfView?.orientation {
            newMessage.orientation = currentCameraOrientation
            messages.append(newMessage)
            lastPlacedMessage = newMessage
        }
    }

    func createMessage(withContent content: String, atLocation location: CLLocation) {
        let newMessage = Message(messageContent: content, location: location)

        messages.append(newMessage)
        lastPlacedMessage = newMessage

    }

    func reactToTouchesBegan(_ touches: Set<UITouch>, with message: String, with event: UIEvent?, in sceneView: ARSCNView) {

        guard let touchLocation = touches.first?.location(in: sceneView) else { return }

        // Gets the camera's position and places an anchor there
        guard let cameraPosition = getCameraPosition(in: sceneView) else { return }
        var worldPosition = cameraPosition + getDirection(for: touchLocation, in: sceneView)

        worldPosition.z *= 2

        // Adding a new message
        createMessage(atPoint: worldPosition, withContent: message, inView: sceneView)

        if let newMessage = self.lastPlacedMessage {
            // Upload msg if just added
            uploadMessage(message: newMessage)

            newMessage.isPlaced = true
            sceneView.scene.rootNode.addChildNode(newMessage)
        }
    }


    func startFetchTimer(inView sceneView: ARSCNView) {
        fetchTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            if let currentLocation = self.locationManager.currentLocation {
                self.fetchMessage(userCoordinate: currentLocation.coordinate, onComplete: { self.displayFetchedMessages(inView: sceneView) })
            }
        }
    }

    func stopFetchTimer() {
        fetchTimer!.invalidate()
    }

    func displayFetchedMessages(inView sceneView: ARSCNView) {

        for message in self.messages {
            // Skips messages that were already placed
            if message.isPlaced {
                continue
            }
            self.lastPlacedMessage = message

            // Randomly creates anchors around the user
            if let currentFrame = sceneView.session.currentFrame {

                // Randomly place point in AR world
                let randomPoint = CGPoint(
                    x: CGFloat(arc4random()) / CGFloat(UInt32.max),
                    y: CGFloat(arc4random()) / CGFloat(UInt32.max)
                )
                guard let testResult = currentFrame.hitTest(randomPoint, types: .featurePoint).first else { return }
                let objectPoint = SCNVector3(
                    /* Converting 4x4 matrix into x,y,z point */
                    testResult.worldTransform.columns.3.x * Float.random(min: -10, max: 10),
                    testResult.worldTransform.columns.3.y * Float.random(min: Float(-message.location.altitude), max: Float(message.location.altitude)),
                    testResult.worldTransform.columns.3.z * Float.random(min: 2, max: 4)
                )

                message.position = objectPoint
                sceneView.scene.rootNode.addChildNode(message)

            }
        }

        turnMessagesToUser(inView: sceneView)
    }

    func turnMessagesToUser(inView sceneView: ARSCNView) {
        for message in messages {
            // Make message face camera
            if let currentCameraOrientation = sceneView.pointOfView?.orientation {
                message.orientation = currentCameraOrientation
            }
        }
    }

    func clearAllMessages() {
        for message in messages {
            unloadMessage(messageToDelete: message)
        }
        messages.removeAll()
        lastPlacedMessage = nil
    }

    func unloadMessage(messageToDelete: Message) {
        DispatchQueue.global().async {
            SCNTransaction.animationDuration = 1.0
            messageToDelete.opacity = 0
            messageToDelete.removeFromParentNode()
        }
    }

    // We use this to determine the location of a tap. In the 3D world, we would like this to refer to a direction.
    func getDirection(for point: CGPoint, in view: SCNView) -> SCNVector3 {
        let farPoint = view.unprojectPoint(SCNVector3(Float(point.x), Float(point.y), 1))
        let nearPoint = view.unprojectPoint(SCNVector3(Float(point.x), Float(point.y), 0))
        let direction = (farPoint - nearPoint).normalized()

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


    /**
     Upload message created by users to the server. status will be printed.
     - parameter userLocation: user location
     - Returns: Void
     */
    func uploadMessage(message: Message) {
        var uploading_message = [String: String]()
        uploading_message["message"] = message.messageContent
        uploading_message["posterId"] = "anonymous"
        uploading_message["lat"] = "\(message.location.coordinate.latitude)"
        uploading_message["lon"] = "\(message.location.coordinate.longitude)"
        uploading_message["altitude"] = "\(message.location.altitude)"
        uploading_message["color"] = "blue"

        HttpHandler().makeAPICall(
            url: "http://188.166.209.81:3001/addNote",
            params: uploading_message,
            method: .POST,
            success: {(res, error) in
                print(res ?? "success empty res", error ?? "|empty error")
        },
            failure: {(res, error) in
                print(res ?? "failure empty res", error ?? "|empty error")
        }
        )
    }

    /**
     Fetch messages surrounding user's location. self.messages will be reassigned by fetched messaages
     - parameter userLocation: user location
     - parameter success: on success callback
     - parameter failure: on failure callback
     - Returns: Void
     */
    func fetchMessage(userCoordinate: CLLocationCoordinate2D, onComplete:@escaping () -> Void) {

        guard let currentLocation = locationManager.currentLocation else { return }

        clearAllMessages()

        var fetchingPrams = [String: String]()
        //        fetchingPrams["lat"] = "\(userCoordinate.latitude)"
        //        fetchingPrams["lon"] = "\(userCoordinate.longitude)"

        fetchingPrams["lat"] = "\(currentLocation.coordinate.latitude)"
        fetchingPrams["lon"] = "\(currentLocation.coordinate.longitude)"
        fetchingPrams["range"] = "25"
        //        fetchingPrams["altitude"] = "\(currentLocation.altitude)"

        HttpHandler().makeAPICall(
            url: "http://188.166.209.81:3001/notes",
            params: fetchingPrams,
            method: .GET,
            success: {(res, error) in

                print("fetching messages")

                self.clearAllMessages()

                guard let jsonData = res?.data(using: .utf8) else {return}

                let strucFetchedMessages = try! JSONDecoder().decode([StructNewMessage].self, from: jsonData)
                if (strucFetchedMessages.count > 0) {
                    for i in 0..<strucFetchedMessages.count {


                        let fetchedMessage = strucFetchedMessages[i].message
                        let fetchedLatitude = strucFetchedMessages[i].location.lat
                        let fetchedLongitude = strucFetchedMessages[i].location.lon
                        let fetchedAltitude = strucFetchedMessages[i].location.altitude

                        print("--------------")
                        print(fetchedMessage)
                        print(fetchedLatitude)
                        print(fetchedLongitude)
                        print(fetchedAltitude)
                        print("--------------")

                        self.createMessage(withContent: fetchedMessage, atLocation: CLLocation(coordinate: CLLocationCoordinate2D(latitude: fetchedLatitude, longitude: fetchedLongitude), altitude: fetchedAltitude))
                    }
                }

                onComplete()
        },
            failure: {(res, error) in
                print(res ?? "failure empty res", error ?? "empty error")
                //                failure(res, error)
        }
        )
    }
}
