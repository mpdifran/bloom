//
//  Font+Rounded.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-18.
//

import SwiftUI

extension UIFont {

    var rounded: UIFont {
        guard let desc = self.fontDescriptor.withDesign(.rounded) else { return self }

        return UIFont(descriptor: desc, size: self.pointSize)
    }
}
