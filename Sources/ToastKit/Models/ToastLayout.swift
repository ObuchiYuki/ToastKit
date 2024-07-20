import UIKit

open class ToastLayout {
    open var iconSize: CGSize
    
    open var margins: UIEdgeInsets
    
    public init(iconSize: CGSize, margins: UIEdgeInsets) {
        self.iconSize = iconSize
        self.margins = margins
    }
}
