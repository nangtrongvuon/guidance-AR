//
//  Message.swift
//  Guidance
//
//  Created by Dzũng Lê on 30/10/2017.
//  Copyright © 2017 Dzũng Lê. All rights reserved.
//

import Foundation
import ARKit
import SceneKit

class Message: SCNNode {
    
    var messageContent: String?
    
    init(messageContent: String, point: SCNVector3) {
        super.init()
        loadMessageAndBackground(message: messageContent, atPoint: point)
    }
    
    override init() {
        super.init()
    }
    
    func loadMessageAndBackground(message: String, atPoint point: SCNVector3) {
        
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
//        guard let sceneViewOrientation = sceneView.pointOfView?.orientation else { return SCNNode() }
        
//        self.orientation = sceneViewOrientation
        
        self.addChildNode(boxNode)
        self.addChildNode(messageNode)
        
        self.position = point
        self.scale = SCNVector3(0.005, 0.005, 0.005)
        
        messageNode.position.z += 0.02
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func center(node: SCNNode) {
        let (min, max) = node.boundingBox
        
        let dx = min.x + 0.5 * (max.x - min.x)
        let dy = min.y + 0.5 * (max.y - min.y)
        let dz = min.z + 0.5 * (max.z - min.z)
        node.pivot = SCNMatrix4MakeTranslation(dx, dy, dz)
    }
}
