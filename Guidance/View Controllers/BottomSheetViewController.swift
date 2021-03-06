//
//  BottomSheetViewController.swift
//  Guidance
//
//  Created by Dzũng Lê on 28/11/2017.
//  Copyright © 2017 Dzũng Lê. All rights reserved.
//

// Credits: https://github.com/AhmedElassuty/BottomSheetController

import UIKit

protocol BottomSheetViewControllerDelegate: class {
    func showBottomSheet(withMessage message: Message)
    func markBottomSheetAsDismissed()
}

class BottomSheetViewController: UIViewController {
    @IBOutlet var bottomSheetView: UIView!
    @IBOutlet weak var rateUpButton: UIButton!
    @IBOutlet weak var rateDownButton: UIButton!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var messageContentView: UITextView!
    @IBOutlet weak var scoreLabel: UILabel!

    weak var delegate: BottomSheetViewControllerDelegate?
    var currentMessage: Message?

    let fullView: CGFloat = 100
    var partialView: CGFloat {
        return UIScreen.main.bounds.height - (rateUpButton.frame.maxY + UIApplication.shared.statusBarFrame.height)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        roundViews()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        prepareBackgroundView()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    func refreshBottomView() {
        if let message = currentMessage {
            self.authorLabel.text = message.author
            self.messageContentView.text = message.messageContent
            self.scoreLabel.text = message.messageScoreString

            // Aesthestics
            if message.messageScore >= 0 {
                self.scoreLabel.textColor = UIColor.blue
            } else {
                self.scoreLabel.textColor = UIColor.red
            }
        }
    }

    // For aesthestics

    func roundViews() {
        bottomSheetView.layer.cornerRadius = 5
        rateUpButton.layer.cornerRadius = 10
        rateDownButton.layer.cornerRadius = 10
        messageContentView.layer.cornerRadius = 10

        rateUpButton.layer.borderColor = UIColor.init(displayP3Red: 0, green: 148/225, blue: 247.0/255, alpha: 1).cgColor
        rateDownButton.layer.borderColor = UIColor.init(displayP3Red: 247.0/255, green: 0, blue: 0, alpha: 1).cgColor

        bottomSheetView.clipsToBounds = true
    }

    @IBAction func dismiss(_ sender: Any) {
        closeBottomSheet()
    }

    func displayBottomSheet() {
        UIView.animate(withDuration: 0.5, animations: { [weak self] in
            let frame = self?.view.frame
            let yComponent = self?.partialView
            self?.view.frame = CGRect(x: 0, y: yComponent!, width: frame!.width, height: frame!.height)
        })
    }

    func closeBottomSheet() {

        UIView.animate(withDuration: 0.5, animations: {
            let frame = self.view.frame
            self.view.frame = CGRect(x: 0, y: self.partialView + frame.height, width: frame.width, height: frame.height)
        })

        delegate?.markBottomSheetAsDismissed()

    }

    func prepareBackgroundView() {

        let blurEffect = UIBlurEffect.init(style: .light)
        let visualEffect = UIVisualEffectView.init(effect: blurEffect)
        let blurredView = UIVisualEffectView.init(effect: blurEffect)

        blurredView.contentView.addSubview(visualEffect)

        visualEffect.frame = self.view.bounds
        blurredView.frame = self.view.bounds

        view.insertSubview(blurredView, at: 0)
    }

    @IBAction func rateUpMessage(_ sender: Any) {

        if let messageToRate = currentMessage {

            // If user hasn't voted
            if !rateUpButton.isSelected && !rateDownButton.isSelected {
                messageToRate.modifyScore(by: 1)
                rateUpButton.isSelected = true
                rateUpButton.backgroundColor = UIColor.blue

                refreshBottomView()

            }
            // User already voted down
            else if rateDownButton.isSelected {
                messageToRate.modifyScore(by: 2)

                rateUpButton.isSelected = true
                rateUpButton.backgroundColor = UIColor.blue

                rateDownButton.isSelected = false
                rateDownButton.backgroundColor = UIColor.clear

                refreshBottomView()
            }
            // User already voted up
            else if rateUpButton.isSelected {
                messageToRate.modifyScore(by: -1)
                rateUpButton.isSelected = false
                rateUpButton.backgroundColor = UIColor.clear

                refreshBottomView()
            }
        }
    }
    @IBAction func rateDownMessage(_ sender: Any) {
        if let messageToRate = currentMessage {

            // If user hasn't voted
            if !rateUpButton.isSelected  && !rateDownButton.isSelected {
                messageToRate.modifyScore(by: -1)
                rateDownButton.isSelected = true
                rateDownButton.backgroundColor = UIColor.red

                refreshBottomView()

            }

            // User already voted up
            else if rateUpButton.isSelected {
                messageToRate.modifyScore(by: -2)

                rateUpButton.isSelected = false
                rateUpButton.backgroundColor = UIColor.clear

                rateDownButton.isSelected = true
                rateDownButton.backgroundColor = UIColor.red

                refreshBottomView()
            }

            // User already voted down
            else if rateDownButton.isSelected {
                messageToRate.modifyScore(by: 1)
                rateDownButton.isSelected = false
                rateDownButton.backgroundColor = UIColor.clear

                refreshBottomView()
            }
        }
    }

    /*
     // MARK: - Navigation

     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */

}
