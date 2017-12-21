//
//  ViewController+Actions.swift
//  Guidance
//
//  Created by Dzũng Lê on 29/10/2017.
//  Copyright © 2017 Dzũng Lê. All rights reserved.
//

import Foundation
import SceneKit

extension MainViewController: UIPopoverPresentationControllerDelegate {

    @IBAction func refreshView(_ button: UIButton) {

        if !isFetchingMessage {
            isFetchingMessage = true
            DispatchQueue.main.async {
                // Show progress indicator
                self.spinner = UIActivityIndicatorView()
                self.spinner!.center = self.refreshButton.center
                self.spinner!.bounds.size = CGSize(width: self.refreshButton.bounds.width - 5, height: self.refreshButton.bounds.height - 5)
                self.refreshButton.setImage(#imageLiteral(resourceName: "buttonring"), for: [])
                self.sceneView.addSubview(self.spinner!)
                self.spinner!.startAnimating()
                self.messageManager.startFetchTimer(inView: self.sceneView)
            }
        } else {
            isFetchingMessage = false
            DispatchQueue.main.async {
                // Remove progress indicator
                self.spinner?.removeFromSuperview()
                self.refreshButton.setImage(#imageLiteral(resourceName: "restart"), for: [])
                self.messageManager.stopFetchTimer()
            }
        }
    }

    @IBAction func addModeToggle(_ button: UIButton) {
        let addMessageView = AddMessageViewController.instance()
        let nav = UINavigationController(rootViewController: addMessageView as UIViewController)
        nav.modalPresentationStyle = .popover
        addMessageView.delegate = self

        if let popover = nav.popoverPresentationController {
            popover.delegate = self
            addMessageView.preferredContentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height / 3)
            popover.sourceView = self.addModeButton
            popover.sourceRect = self.addModeButton.bounds
            self.present(nav, animated: true, completion: nil)
        }
    }

    @IBAction func showMapView (_ button: UIButton){
        let popMapView = MapViewController.instance()
        let nav = UINavigationController(rootViewController: popMapView as UIViewController)
        nav.isNavigationBarHidden = true
        nav.modalPresentationStyle = .popover

        if let popover = nav.popoverPresentationController {
            popover.delegate = self
            popMapView.preferredContentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height)
            popover.sourceView = self.showMapButton
            popover.sourceRect = self.showMapButton.bounds
            self.present(nav, animated: true, completion: nil)
        }
    }
}
