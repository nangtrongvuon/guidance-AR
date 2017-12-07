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
    
    @IBAction func showMapView (_ button: UIButton){
        let popMapView = MapViewController.instance()
        
        let nav = UINavigationController(rootViewController: popMapView as UIViewController)
        nav.isNavigationBarHidden = true

        nav.modalPresentationStyle = .popover
        if let popover = nav.popoverPresentationController {
            popover.delegate = self
            popMapView.preferredContentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height)
            popover.sourceView = showMapButton
            popover.sourceRect = showMapButton.bounds
            self.present(nav, animated: true, completion: nil)
        }
    }
    // Toggles between add and view mode
    @IBAction func addModeToggle(_ button: UIButton) {
        let addMessageView = AddMessageViewController.instance()
        let nav = UINavigationController(rootViewController: addMessageView as UIViewController)
        nav.modalPresentationStyle = .popover

        DispatchQueue.global(qos: .userInteractive).async { [unowned self] in 

            addMessageView.delegate = self
            if let popover = nav.popoverPresentationController {
                popover.delegate = self
                addMessageView.preferredContentSize = CGSize(width: self.view.frame.width, height: self.view.frame.height / 3)
                popover.sourceView = self.addModeButton
                popover.sourceRect = self.addModeButton.bounds
                self.present(nav, animated: true, completion: nil)
            }
        }
    }
}
