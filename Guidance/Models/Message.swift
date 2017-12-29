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

    var author = UIDevice.current.name
    var messageContent: String?
    var messageScore = 0
    var isPlaced = false

    var messageScoreString: String {
        get {
            if messageScore > 0 {
                return "+\(messageScore)"
            } else {
                return "\(messageScore)"
            }
        }
    }

    var messageFront = SCNPlane()

    init(messageContent: String, location: CLLocation) {
        self.messageContent = messageContent
        super.init(location: location)
        create(message: messageContent)
        print("created message at \(location), at \(location.altitude)")
    }

    init(messageContent: String, location: CLLocation, point: SCNVector3) {
        self.messageContent = messageContent
        super.init(location: location)
        create(message: messageContent, point: point)
        print("created message at \(location), at \(location.altitude)")
    }

    func setupTextImage(message: String) -> [UIImage] {

        var results = [UIImage]()
            let messageView = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 500.0, height: 500.0)))
            let messageLabel = EdgeInsetLabel(frame: CGRect(origin: .zero, size: CGSize(width: 500.0, height: 500.0)))

            messageView.backgroundColor = UIColor.blue.withAlphaComponent(0.75)
            messageLabel.textInsets = UIEdgeInsetsMake(10, 20, 10, 20)
            messageLabel.numberOfLines = 0
            messageLabel.text = message
            messageLabel.textAlignment = .center

            let sizeToFit = CGSize(width: messageLabel.frame.size.width, height: CGFloat.greatestFiniteMagnitude)
            let textSize = messageLabel.sizeThatFits(sizeToFit)

            let messageViewOrigin = CGPoint(x: 10, y: (messageView.frame.size.height - textSize.height) / 2)

            messageView.frame = CGRect(origin: messageViewOrigin, size: CGSize(width: textSize.width, height: textSize.height))

            messageLabel.sizeToFit()

            messageLabel.textColor = UIColor.white
            messageLabel.font = UIFont(name: "San Francisco", size: 16)

            // creates blank image for backside of messages
            let backsideImage = self.generateImageFromView(inputView: messageView)
            messageView.addSubview(messageLabel)
            let textImage = self.generateImageFromView(inputView: messageView)

            results.append(textImage)
            results.append(backsideImage)

        return results
    }

    // Setups the message
    func setupMessageNode(textImage: UIImage, backImage: UIImage) {
        self.messageFront = SCNPlane(width: textImage.size.width / 100, height: textImage.size.height / 100)
        self.messageFront.firstMaterial!.diffuse.contents = textImage
        self.messageFront.cornerRadius = 0.1

        let messageBack = SCNPlane(width: textImage.size.width / 100, height: textImage.size.height / 100)
        messageBack.firstMaterial!.diffuse.contents = backImage
        messageBack.firstMaterial!.isDoubleSided = true
        messageBack.cornerRadius = 0.1

        let boxNode = SCNNode(geometry: self.messageFront)
        let backsideNode = SCNNode(geometry: messageBack)

        self.addChildNode(boxNode)
        self.addChildNode(backsideNode)
    }

    func create(message: String) {
        DispatchQueue.main.async { [unowned self] in
            let images = self.setupTextImage(message: message)

            // Multithread on off queue
            DispatchQueue.global(qos: .userInitiated).async { [unowned self] in
                self.setupMessageNode(textImage: images[0], backImage: images[1])
                self.messageContent = message

            }
        }
    }
    
    func create(message: String, point: SCNVector3) {
        create(message: message)
        self.position = point
        self.messageContent = message
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

    func modifyScore(by score: Int) {
        // Modifies the message's score
       self.messageScore += score
    }
}

// Helper class to create margins for the UIView

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

