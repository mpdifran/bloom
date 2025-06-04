import SwiftUI
import DataContainer

extension Reminder {
  var color: Color {
    if colorHex.isEmpty {
      return .accentColor
    }
    return Color(hex: colorHex) ?? .accentColor
  }
}