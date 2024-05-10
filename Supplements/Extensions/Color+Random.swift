//
//  Color+Random.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import AppUI

extension Color {

    static func indexedSet(index: Int) -> Color {
        let colors: [Color] = [
            Color(hex: 0xffd380),
            Color(hex: 0xffa600),
            Color(hex: 0xff8531),
            Color(hex: 0xff6361),
            Color(hex: 0xbc5090),
            Color(hex: 0x8a508f),
            Color(hex: 0x2c4875),
            Color(hex: 0x003f5c),
            Color(hex: 0x00202e)
        ]
        return colors[index % colors.count]
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
