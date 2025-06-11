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

    case ultramarine
    case lilac
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
      "BloomAppIconLilac"
    case .ultramarine:
      nil
    case .sunflower:
      "BloomAppIconOrange"
    }
  }
}

@MainActor @Observable
final class ThemeController {
  static let shared = ThemeController()

  private(set) var theme: Theme = .ultramarine

  private init() {
    UserDefaults.group.register(defaults: [.Key.theme: Theme.ultramarine.rawValue])
    if let rawTheme = UserDefaults.group.string(forKey: .Key.theme), let theme = Theme(rawValue: rawTheme) {
      self.theme = theme
      Task {
        await set(theme: theme)
      }
    }
  }

  func set(theme: ThemeController.Theme) async {
    let didChange = theme != self.theme
    self.theme = theme

    guard didChange else { return }

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
