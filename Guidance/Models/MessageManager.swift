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

class MessageManager {
    struct Location: Codable {
        let lat, lon: Double
    }
    struct StructNewMessage: Codable {
        let message, color: String
        let location: Location
        //        let posterId: Int
        
    }
    
    var messages = [Message]()
    let locationManager = LocationManager()

    var lastPlacedMessage: Message?

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
            uploadMessage(message: newMessage)
    }

    func clearAllMessages() {
        for message in messages {
            unloadMessage(messageToDelete: message)
        }
    }

    func unloadMessage(messageToDelete: Message) {
        
//        guard let deleteIndex = messages.index(of: messageToDelete) else { return }

        DispatchQueue.global().async {

            SCNTransaction.animationDuration = 1.0
            messageToDelete.opacity = 0
            messageToDelete.removeFromParentNode()
        }

//        self.messages.remove(at: deleteIndex)

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

        var fetchingPrams = [String: String]()
//        fetchingPrams["lat"] = "\(userCoordinate.latitude)"
//        fetchingPrams["lon"] = "\(userCoordinate.longitude)"

        fetchingPrams["lat"] = "\(currentLocation.coordinate.latitude)"
        fetchingPrams["lon"] = "\(currentLocation.coordinate.longitude)"
//        fetchingPrams["altitude"] = "\(currentLocation.altitude)"

        HttpHandler().makeAPICall(
            url: "http://188.166.209.81:3001/notes",
            params: fetchingPrams,
            method: .GET,
            success: {(res, error) in

                print("fetching messages")
                print(res)
                guard let jsonData = res?.data(using: .utf8) else {return}
                var newMessages = [Message]() ;
                
                let strucFetchedMessages = try! JSONDecoder().decode([StructNewMessage].self, from: jsonData)
                if (strucFetchedMessages.count > 0) {
                    for i in 0..<strucFetchedMessages.count {
                        print("--------------")
                        print(strucFetchedMessages[i].message)
                        print(strucFetchedMessages[i].location.lat)
                        print(strucFetchedMessages[i].location.lon)
                        print(strucFetchedMessages[i].location.lon)
                        print("--------------")
                        newMessages.append(
                            Message(messageContent: strucFetchedMessages[i].message,
                                    location: CLLocation(coordinate: CLLocationCoordinate2D(
                                        latitude: strucFetchedMessages[i].location.lat,
                                        longitude: strucFetchedMessages[i].location.lon), altitude: currentLocation.altitude)
                            )
                        )
                    }
                    self.messages = newMessages
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
