//
//  ToastView.swift
//  ToastKit
//
//  Created by yuki on 2025/03/13.
//

import UIKit

public enum ToastHaptic {
    case success
    case warning
    case error
    case none
    
    func impact() {
        let generator = UINotificationFeedbackGenerator()
        switch self {
        case .success:
            generator.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.success)
        case .warning:
            generator.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.warning)
        case .error:
            generator.notificationOccurred(UINotificationFeedbackGenerator.FeedbackType.error)
        case .none:
            break
        }
    }
}


