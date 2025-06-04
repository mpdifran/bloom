import SwiftUI
import UIKit

extension Color {
  func toHex() -> String? {
    guard let components = UIColor(self).cgColor.components else { return nil }
    
    let r = components[0]
    let g = components.count > 1 ? components[1] : r
    let b = components.count > 2 ? components[2] : r
    
    let rgb = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
    
    return String(format: "%06X", rgb)
  }
}