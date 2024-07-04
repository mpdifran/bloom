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

    init?(hex: String, alpha: Double? = nil) {
        var hexDigits = hex.first == "#" ? String(hex.dropFirst()) : hex
        for digit in hexDigits {
            guard "0123456789abcdefABCDEF".contains(digit) else { return nil }
        }
        if hexDigits.count == 2 { // grayscale
            hexDigits += hexDigits + hexDigits
        }
        if hexDigits.count <= 4 { // #rgb or #rgba
            hexDigits = hexDigits.map { "\($0)\($0)" } .joined(separator: "")
        }
        if hexDigits.count == 6 { // #rrggbb
            hexDigits += "ff"
        }
        // #rrggbbaa
        guard hexDigits.count == 8 else { return nil }

        let digits = Array(hexDigits)
        let rgba = stride(from: 0, to: 8, by: 2).map {
            Double(Int("\(digits[$0])\(digits[$0 + 1])", radix: 16)!) / 255.0
        }
        // TODO: Is this the right color space?
        self = Color(.displayP3, red: rgba[0], green: rgba[1], blue: rgba[2], opacity: alpha ?? rgba[3])
    }
}
