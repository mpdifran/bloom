//
//  ThemeController.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-07.
//

import SwiftUI
import TelemetryDeck

private extension String {
  enum Key {
    static let theme = "ThemeController.Theme"
  }
}

extension ThemeController {
  enum Theme: String, CaseIterable, Identifiable {
    var id: Self { self }

    case lilac
    case ultramarine
    case sunflower
  }
}

extension ThemeController.Theme {
  var name: String {
    switch self {
    case .lilac:
      "Lilac"
    case .ultramarine:
      "Ultramarine"
    case .sunflower:
      "Sunflower"
    }
  }

  var color: Color {
    switch self {
    case .lilac:
      return .lilacTint
    case .ultramarine:
      return .marineTint
    case .sunflower:
      return .sunflowerTint
    }
  }

  var backgroundColor: Color {
    switch self {
    case .lilac:
      return .lilacBackground
    case .ultramarine:
      return .marineBackground
    case .sunflower:
      return .sunflowerBackground
    }
  }

  var appIcon: ImageResource {
    switch self {
    case .lilac:
      return .bloomDisplayAppIconPurple
    case .ultramarine:
      return .bloomDisplayAppIconBlue
    case .sunflower:
      return .bloomDisplayAppIconOrange
    }
  }

  var alternateIconName: String? {
    switch self {
    case .lilac:
      nil
    case .ultramarine:
      "BloomAppIconBlue"
    case .sunflower:
      "BloomAppIconOrange"
    }
  }
}

@MainActor @Observable
final class ThemeController {

  private(set) var theme: Theme = .lilac

  init() {
    UserDefaults.group.register(defaults: [.Key.theme: Theme.lilac.rawValue])
    if let rawTheme = UserDefaults.group.string(forKey: .Key.theme), let theme = Theme(rawValue: rawTheme) {
      Task {
        await set(theme: theme)
      }
    }
  }

  func set(theme: ThemeController.Theme) async {
    self.theme = theme
    UserDefaults.group.set(theme.rawValue, forKey: .Key.theme)

    await updateAppIconForTheme()

    TelemetryDeck.signal("Updated Theme", parameters: ["selectedTheme": theme.name])
  }

  func updateAppIconForTheme() async {
    do {
      try await UIApplication.shared.setAlternateIconName(theme.alternateIconName)
    } catch {
      print(error)
      TelemetryDeck.errorOccurred(
        id: "ThemeController.updateTheme",
        category: .thrownException,
        message: error.localizedDescription
      )
    }
  }
}
