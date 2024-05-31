//
//  Color+Brightness.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-31.
//

import SwiftUI

extension Color {
    func lighter(by percentage: CGFloat = 0.3) -> Color {
        return self.adjustBrightness(by: abs(percentage))
    }

    func darker(by percentage: CGFloat = 0.3) -> Color {
        return self.adjustBrightness(by: -abs(percentage))
    }

    private func adjustBrightness(by percentage: CGFloat) -> Color {
        let uiColor = UIColor(self)

        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

        brightness += (brightness * percentage)
        brightness = min(max(brightness, 0), 1)

        return Color(UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha))
    }
}
