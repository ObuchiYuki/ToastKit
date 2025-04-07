//
//  ToastLayout.swift
//  ToastKit
//
//  Created by yuki on 2025/03/13.
//

import UIKit

final class ToastLayout {
    var iconSize: CGSize
    
    var margins: UIEdgeInsets
    
    init(iconSize: CGSize, margins: UIEdgeInsets) {
        self.iconSize = iconSize
        self.margins = margins
    }
}
