//
//  ToastView.swift
//  ToastKit
//
//  Created by yuki on 2025/03/13.
//

import UIKit

public enum ToastIconPreset {
    case done
    case error
    case spin(_ style: UIActivityIndicatorView.Style)
    case custom(_ image: UIImage)
}

public extension ToastIconPreset {
    func createView() -> UIView {
        switch self {
        case .done:
            let view = ToastIconDoneView()
            return view
        case .error:
            let view = ToastIconErrorView()
            view.tintColor = UIColor.systemRed
            return view
        case .spin(let style):
            let view = UIActivityIndicatorView(style: style)
            view.startAnimating()
            return view
        case .custom(let image):
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFit
            return imageView
        }
    }
    
    func getHaptic() -> ToastHaptic {
        switch self {
        case .error: return .error
        case .done: return .success
        case .spin(_): return .none
        case .custom(_): return .success
        }
    }
}

extension ToastLayout {    
    convenience init() {
        self.init(
            iconSize: .init(
                width: Self.defaultIconSideSize,
                height: Self.defaultIconSideSize
            ),
            margins: .init(
                top: Self.defaultVerticallInset,
                left: Self.defaultHorizontalInset,
                bottom: Self.defaultVerticallInset,
                right: Self.defaultHorizontalInset
            )
        )
    }
    
    static func message() -> ToastLayout {
        let layout = ToastLayout()
        return layout
    }
    
    convenience init(for preset: ToastIconPreset) {
        switch preset {
        case .done:
            self.init()
            iconSize = .init(width: 24, height: 24)
        case .error:
            self.init()
            iconSize = .init(width: 14, height: 14)
            margins.left = 19
            margins.right = margins.left
        case .spin(_):
            self.init()
        case .custom(_):
            self.init()
        }
    }
        
    private static var defaultIconSideSize: CGFloat { 28 }
    private static var defaultSpaceBetweenIconAndTitle: CGFloat { 26 }
    private static var defaultVerticallInset: CGFloat { 8 }
    private static var defaultHorizontalInset: CGFloat { 15 }
}

