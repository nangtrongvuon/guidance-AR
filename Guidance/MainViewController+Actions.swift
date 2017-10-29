//
//  ViewController+Actions.swift
//  Guidance
//
//  Created by Dzũng Lê on 29/10/2017.
//  Copyright © 2017 Dzũng Lê. All rights reserved.
//

import Foundation
import SceneKit

extension MainViewController {
    
    // Toggles between add and view mode
    @IBAction func addModeToggle(_ button: UIButton) {
//        self.isAddingMessage = !self.isAddingMessage
        
//        print(isAddingMessage)
        
        let addMessageView = AddMessageViewController.instance()
        navigationController?.pushViewController(addMessageView, animated: true)
        
    }
}
