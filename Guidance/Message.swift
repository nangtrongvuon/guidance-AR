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
import CoreLocation

class Message: LocationNode {
    
    var messageContent: String?
    var messageScore = 0
    var frontsideBox = SCNPlane()
    
    init(messageContent: String, point: SCNVector3) {
        super.init(location: LocationManager().currentLocation)
        loadMessage(message: messageContent, atPoint: point)
        print("created message at \(location), at \(location.altitude)")
    }
    
    init(messageContent: String) {
        super.init(location: LocationManager().currentLocation)
        loadMessage(message: messageContent)
        print("created message at \(location), at \(location.altitude)")
    }
    
    init(messageContent: String, coordinates: CLLocationCoordinate2D) {
        super.init(location: CLLocation(coordinate: coordinates, altitude: 11))
        loadMessage(message: messageContent)
        print("created message at \(location), at \(location.altitude)")
    }
    
    
    func loadMessage(message: String, atPoint point: SCNVector3) {
        
        //        let message = SCNText(string: message, extrusionDepth: 0)
        //        message.containerFrame = CGRect(origin: .zero, size: CGSize(width: 100.0, height: 500.0))
        //        message.isWrapped = true
        //
        //        message.font = UIFont(name: "San Francisco", size: 16)
        //        message.flatness = 1
        //        let messageNode = SCNNode(geometry: message)
        //        center(node: messageNode)
        //
        DispatchQueue.global(qos: .userInitiated).async {
            let messageView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 500.0, height: 500.0)))
            let messageLabel = EdgeInsetLabel(frame: CGRect(origin: .zero, size: CGSize(width: 500.0, height: 500.0)))

            messageView.backgroundColor = UIColor.blue.withAlphaComponent(0.75)

            messageLabel.textInsets = UIEdgeInsetsMake(10, 20, 10, 20)

            messageLabel.numberOfLines = 0
            messageLabel.text = message
            messageLabel.text!.append("\n Score: \(self.messageScore)")
            messageLabel.textAlignment = .center

            let sizeToFit = CGSize(width: messageLabel.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
            let textSize = messageLabel.sizeThatFits(sizeToFit)

            let messageViewOrigin = CGPoint(x: 10, y: (messageView.frame.size.height - textSize.height) / 2)

            messageView.frame = CGRect(origin: messageViewOrigin, size: CGSize(width: textSize.width, height: textSize.height))

            let backside = self.generateImageFromView(inputView: messageView)

            messageView.addSubview(messageLabel)
            messageLabel.sizeToFit()

            messageLabel.textColor = UIColor.white
            messageLabel.font = UIFont(name: "San Francisco", size: 16)

            let textImage = self.generateImageFromView(inputView: messageView)

            self.frontsideBox = SCNPlane(width: textImage.size.width / 100, height: textImage.size.height / 100)
            self.frontsideBox.firstMaterial!.diffuse.contents = textImage
            self.frontsideBox.cornerRadius = 0.1

            let backsideBackgroundBox = SCNPlane(width: textImage.size.width / 100, height: textImage.size.height / 100)
            backsideBackgroundBox.firstMaterial!.diffuse.contents = backside
            backsideBackgroundBox.firstMaterial!.isDoubleSided = true
            backsideBackgroundBox.cornerRadius = 0.1

            let boxNode = SCNNode(geometry: self.frontsideBox)
            let backsideNode = SCNNode(geometry: backsideBackgroundBox)

            self.addChildNode(boxNode)
            self.addChildNode(backsideNode)

            self.position = point
        }
    }
    
    func loadMessage(message: String) {
        DispatchQueue.global(qos: .userInitiated).async {

            let messageView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 500.0, height: 500.0)))
            let messageLabel = EdgeInsetLabel(frame: CGRect(origin: .zero, size: CGSize(width: 500.0, height: 500.0)))

            messageView.backgroundColor = UIColor.blue.withAlphaComponent(0.75)

            messageLabel.textInsets = UIEdgeInsetsMake(10, 20, 10, 20)

            messageLabel.numberOfLines = 0
            messageLabel.text = message
            messageLabel.text!.append("\n Score: \(self.messageScore)")
            messageLabel.textAlignment = .center

            let sizeToFit = CGSize(width: messageLabel.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
            let textSize = messageLabel.sizeThatFits(sizeToFit)

            let messageViewOrigin = CGPoint(x: 10, y: (messageView.frame.size.height - textSize.height) / 2)

            messageView.frame = CGRect(origin: messageViewOrigin, size: CGSize(width: textSize.width, height: textSize.height))

            let backside = self.generateImageFromView(inputView: messageView)

            messageView.addSubview(messageLabel)
            messageLabel.sizeToFit()

            messageLabel.textColor = UIColor.white
            messageLabel.font = UIFont(name: "San Francisco", size: 16)

            let textImage = self.generateImageFromView(inputView: messageView)

            self.frontsideBox = SCNPlane(width: textImage.size.width / 100, height: textImage.size.height / 100)
            self.frontsideBox.firstMaterial!.diffuse.contents = textImage
            self.frontsideBox.cornerRadius = 0.1

            let backsideBackgroundBox = SCNPlane(width: textImage.size.width / 100, height: textImage.size.height / 100)
            backsideBackgroundBox.firstMaterial!.diffuse.contents = backside
            backsideBackgroundBox.firstMaterial!.isDoubleSided = true
            backsideBackgroundBox.cornerRadius = 0.1

            let boxNode = SCNNode(geometry: self.frontsideBox)
            let backsideNode = SCNNode(geometry: backsideBackgroundBox)

            self.addChildNode(boxNode)
            self.addChildNode(backsideNode)

        }
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
    
    // Helper
    func generateImageFromView(inputView: UIView) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, true, 0)
        inputView.drawHierarchy(in: inputView.bounds, afterScreenUpdates: true)
        let uiImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return uiImage
    }

    func updateScore() {
        self.messageScore += 1
        DispatchQueue.global(qos: .userInitiated).async {
            let messageView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 500.0, height: 500.0)))
            let messageLabel = EdgeInsetLabel(frame: CGRect(origin: .zero, size: CGSize(width: 500.0, height: 500.0)))

            messageView.backgroundColor = UIColor.blue.withAlphaComponent(0.75)

            messageLabel.textInsets = UIEdgeInsetsMake(10, 20, 10, 20)

            messageLabel.numberOfLines = 0
            messageLabel.text = self.messageContent
            messageLabel.text!.append("\n Score: \(self.messageScore)")
            messageLabel.textAlignment = .center

            let textImage = self.generateImageFromView(inputView: messageView)

            self.frontsideBox.firstMaterial!.diffuse.contents = textImage
        }
    }
}

class EdgeInsetLabel: UILabel {
    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }
    
    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = UIEdgeInsetsInsetRect(bounds, textInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top,
                                          left: -textInsets.left,
                                          bottom: -textInsets.bottom,
                                          right: -textInsets.right)
        return UIEdgeInsetsInsetRect(textRect, invertedInsets)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, textInsets))
    }
}

