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

    @IBAction func addModeToggle(_ button: UIButton) {
        var addMessageView = AddMessageViewController()
        var nav = UINavigationController()

        DispatchQueue.main.async { [unowned self] in
            addMessageView = AddMessageViewController.instance()
            nav = UINavigationController(rootViewController: addMessageView as UIViewController)
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
    }

    @IBAction func showMapView (_ button: UIButton){
        var popMapView = MapViewController()
        var nav = UINavigationController()

        DispatchQueue.main.async { [unowned self] in
            popMapView = MapViewController.instance()

            nav = UINavigationController(rootViewController: popMapView as UIViewController)
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
}
