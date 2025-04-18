//
//  UIFont+Ex.swift
//  ToastKit
//
//  Created by yuki on 2025/03/13.
//

import UIKit

extension UIFont {
    static func preferredFont(forTextStyle style: TextStyle, weight: Weight, addPoints: CGFloat = 0) -> UIFont {
        let descriptor = UIFontDescriptor.preferredFontDescriptor(withTextStyle: style)
        let font = UIFont.systemFont(ofSize: descriptor.pointSize + addPoints, weight: weight)
        let metrics = UIFontMetrics(forTextStyle: style)
        return metrics.scaledFont(for: font)
    }
}
