import UIKit

extension ToastView {
    public static func present(title: String, message: String? = nil, preset: ToastIconPreset, haptic: ToastHaptic, from presentSide: ToastPresentSide = .top, completion: (() -> Void)? = nil) {
        let alertView = ToastView(title: title, message: message, preset: preset)
        alertView.presentSide = presentSide
        alertView.present(haptic: haptic, completion: completion)
    }
    
    public static func present(title: String, message: String? = nil, preset: ToastIconPreset, from presentSide: ToastPresentSide = .top, completion: (() -> Void)? = nil) {
        let alertView = ToastView(title: title, message: message, preset: preset)
        alertView.presentSide = presentSide
        let haptic = preset.getHaptic()
        alertView.present(haptic: haptic, completion: completion)
    }
    
    public static func present(title: String, message: String? = nil, haptic: ToastHaptic, from presentSide: ToastPresentSide = .top, completion: (() -> Void)? = nil) {
        let alertView = ToastView(title: title, message: message)
        alertView.presentSide = presentSide
        alertView.present(haptic: haptic, completion: completion)
    }
    
    public static func presentError(_ error: Error) {
        let toast = ToastView(title: error.localizedDescription, preset: .error)
        toast.present()
    }
}

