//
//  ThemeController.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-07.
//

import SwiftUI

private extension String {
  enum Key {
    static let theme = "ThemeController.Theme"
  }
}

extension ThemeController {
  enum Theme: String {
    case ultramarine
    case lilac
    case sunflower
  }
}

extension ThemeController.Theme {
  var color: Color {
    switch self {
    case .ultramarine:
      return .marineTint
    case .lilac:
      return .lilacTint
    case .sunflower:
      return .sunflowerTint
    }
  }

  var backgroundColor: Color {
    switch self {
    case .ultramarine:
      return .marineBackground
    case .lilac:
      return .lilacBackground
    case .sunflower:
      return .sunflowerBackground
    }
  }
}

@MainActor @Observable
final class ThemeController {

  var theme: Theme = .lilac {
    didSet { UserDefaults.group.set(theme.rawValue, forKey: .Key.theme) }
  }

  init() {
    if let rawTheme = UserDefaults.group.string(forKey: .Key.theme), let theme = Theme(rawValue: rawTheme) {
      self.theme = theme
    }
  }
}
