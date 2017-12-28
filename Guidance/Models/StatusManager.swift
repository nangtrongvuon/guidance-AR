//
//  StatusManager.swift
//  Guidance
//
//  Created by Dzũng Lê on 28/12/2017.
//  Copyright © 2017 Dzũng Lê. All rights reserved.
//  Credits to Apple ARKit example for status implementation

import Foundation
import ARKit

enum StatusType {
    case addingMessage
    case fetchingMessage
    case trackingState
}

extension ARCamera.TrackingState {
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "TRACKING UNAVAILABLE"
        case .normal:
            return "TRACKING NORMAL"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "TRACKING LIMITED\nToo much camera movement"
            case .insufficientFeatures:
                return "TRACKING LIMITED\nNot enough surface detail"
            case .initializing:
                return "Initializing AR Session"
            }
        }
    }
    var recommendation: String? {
        switch self {
        case .limited(.excessiveMotion):
            return "Try slowing down your movement, or reset the session."
        case .limited(.insufficientFeatures):
            return "Try pointing at a flat surface, or reset the session."
        default:
            return nil
        }
    }
}

class StatusManager {

    private var viewController: MainViewController

    init(viewController: MainViewController) {
        self.viewController = viewController
    }


    // Timer for hiding messages
    private var messageHideTimer: Timer?

    // Timer for showing that app is adding a message
    private var addingMessageTimer: Timer?

    // Timer for showing that app is fetching messages
    private var fetchingMessageTimer: Timer?

    // Timer for tracking state escalation
    private var trackingStateFeedback: Timer?

    let blurEffectViewTag = 100
    var schedulingMessagesBlocked = false

    func showMessage(_ text: String, autoHide: Bool = true) {
        DispatchQueue.main.async {
            self.messageHideTimer?.invalidate()

            self.viewController.messageLabel.text = text

            // make sure status is showing
            self.showHideMessage(hide: false, animated: true)

            if autoHide {
                let charCount = text.count
                let displayDuration: TimeInterval = min(10, Double(charCount) / 15.0 + 1.0)
                self.messageHideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false, block: { [weak self] ( _ ) in
                    self?.showHideMessage(hide: true, animated: true) } )
            }
        }
    }

    func scheduleMessage(_ text: String, inSeconds seconds: TimeInterval, statusType: StatusType) {
        guard !schedulingMessagesBlocked else { return }

        var timer: Timer?

        switch statusType {
        case .addingMessage: timer = addingMessageTimer
        case .fetchingMessage: timer = fetchingMessageTimer
        case .trackingState: timer = trackingStateFeedback
        }

        if timer != nil {
            timer!.invalidate()
            timer = nil
        }

        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { [weak self] ( _ ) in
            self?.showMessage(text)
            timer?.invalidate()
            timer = nil
        })

        switch statusType {
        case .addingMessage: timer = addingMessageTimer
        case .fetchingMessage: timer = fetchingMessageTimer
        case .trackingState: timer = trackingStateFeedback
        }
    }

    func cancelScheduledMessage(forType statusType: StatusType) {
        var timer: Timer?
        switch statusType {
        case .addingMessage: timer = addingMessageTimer
        case .fetchingMessage: timer = fetchingMessageTimer
        case .trackingState: timer = trackingStateFeedback
        }

        if timer != nil {
            timer!.invalidate()
            timer = nil
        }
    }

    func cancelAllScheduledMessages(forType statusType: StatusType) {
        cancelScheduledMessage(forType: .addingMessage)
        cancelScheduledMessage(forType: .fetchingMessage)
        cancelScheduledMessage(forType: .trackingState)
    }

    // MARK: - Background Blur

    func blurBackground() {
        let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)
        blurEffectView.frame = viewController.view.bounds
        blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        blurEffectView.tag = blurEffectViewTag
        viewController.view.addSubview(blurEffectView)
    }

    func unblurBackground() {
        for view in viewController.view.subviews {
            if let blurView = view as? UIVisualEffectView, blurView.tag == blurEffectViewTag {
                blurView.removeFromSuperview()
            }
        }
    }

    // MARK: - ARKit

    func showTrackingQualityInfo(for trackingState: ARCamera.TrackingState, autoHide: Bool) {
        showMessage(trackingState.presentationString, autoHide: autoHide)
    }

    func escalateFeedback(for trackingState: ARCamera.TrackingState, inSeconds seconds: TimeInterval) {
        if self.trackingStateFeedback != nil {
            self.trackingStateFeedback!.invalidate()
            self.trackingStateFeedback = nil
        }

        self.trackingStateFeedback = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { _ in
            self.trackingStateFeedback?.invalidate()
            self.trackingStateFeedback = nil

            if let recommendation = trackingState.recommendation {
                self.showMessage(trackingState.presentationString + "\n" + recommendation, autoHide: false)
            } else {
                self.showMessage(trackingState.presentationString, autoHide: false)
            }
        })
    }

    // MARK: - Panel Visibility

    private func showHideMessage(hide: Bool, animated: Bool) {
        if !animated {
            viewController.messageLabel.isHidden = hide
            return
        }

        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: [.allowUserInteraction, .beginFromCurrentState],
                       animations: {
                        self.viewController.messageLabel.isHidden = hide
                        self.updateMessagePanelVisibility()
        }, completion: nil)
    }

    private func updateMessagePanelVisibility() {
        // Show and hide the panel depending whether there is something to show.
        viewController.messagePanel.isHidden = viewController.messageLabel.isHidden
    }
}
