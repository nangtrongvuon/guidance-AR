//
//  MessageManager.swift
//  Guidance
//
//  Created by Dzũng Lê on 30/10/2017.
//  Copyright © 2017 Dzũng Lê. All rights reserved.
//

import Foundation

import ARKit
import SceneKit

class MessageManager {
    
    var messages = [Message]()
    
    var lastPlacedMessage: Message?
    
    func createMessage(atPoint point: SCNVector3, withContent content: String, inView view: ARSCNView) -> Message {
        let newMessage = Message(messageContent: content, point: point)
        
        if let currentCameraOrientation = view.pointOfView?.orientation {
            newMessage.orientation = currentCameraOrientation
            messages.append(newMessage)
            lastPlacedMessage = newMessage
            
        }
        return newMessage
    }
}

