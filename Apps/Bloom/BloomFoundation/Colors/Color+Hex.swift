//
//  Color+Hex.swift
//  BloomFoundation
//
//  Created by Mark DiFranco on 2026-01-27.
//

import SwiftUI

public extension Color {

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
    self = Color(.displayP3, red: rgba[0], green: rgba[1], blue: rgba[2], opacity: alpha ?? rgba[3])
  }

  #if canImport(UIKit)
  /// Convert Color to hex string (e.g., "#4CAF50")
  var hexString: String? {
    guard let cgColor = UIColor(self).cgColor.converted(
      to: CGColorSpace(name: CGColorSpace.sRGB)!,
      intent: .defaultIntent,
      options: nil
    ) else { return nil }

    guard let components = cgColor.components, components.count >= 3 else { return nil }

    let r = Int(components[0] * 255)
    let g = Int(components[1] * 255)
    let b = Int(components[2] * 255)

    return String(format: "#%02X%02X%02X", r, g, b)
  }
  #endif
}
