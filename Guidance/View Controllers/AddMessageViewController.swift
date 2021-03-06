//
//  AddMessageViewController.swift
//  Guidance
//
//  Created by Dzũng Lê on 29/10/2017.
//  Copyright © 2017 Dzũng Lê. All rights reserved.
//

import UIKit

protocol AddMessageViewControllerDelegate: class {
    func addMessageViewController(didFinishAddingMessage message: String)
}

class AddMessageViewController: UIViewController, UITextViewDelegate {

    let maximumWordCount = 150
    
    @IBOutlet weak var addMessageTextView: UITextView!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    weak var delegate: AddMessageViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        // Sets self to be delegate for text view.
        self.addMessageTextView.delegate = self
        
        doneButton.style = .done
        doneButton.isEnabled = false
        
        guard let initialNavController = self.navigationController else { return }
        initialNavController.setNavigationBarHidden(false, animated: true)
        initialNavController.navigationBar.titleTextAttributes = [NSAttributedStringKey.foregroundColor : UIColor.black]
        
        addMessageTextView.textContainerInset = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        
        addMessageTextView.becomeFirstResponder()
    }
    
    // Disable done button if text view is empty
    func textViewDidChange(_ textView: UITextView) {

        self.navigationItem.title = String(describing: maximumWordCount - addMessageTextView.text.count)

        doneButton.isEnabled = !addMessageTextView.text.isEmpty && addMessageTextView.text.count < maximumWordCount
    }

    // MARK: - Navigation
    @IBAction func addNewMessage(_ sender: UIBarButtonItem) {
        if let message = addMessageTextView.text {
            delegate?.addMessageViewController(didFinishAddingMessage: message)
            addMessageTextView.text = ""
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelAddMessage(_ sender: UIBarButtonItem) {
        guard let initialNavController = self.navigationController else { return }
        
        initialNavController.setNavigationBarHidden(true, animated: true)
        addMessageTextView.resignFirstResponder()
        self.dismiss(animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

