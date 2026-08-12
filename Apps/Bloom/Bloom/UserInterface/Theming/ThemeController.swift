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

    case blue
    case purple
    case orange
  }
}

extension ThemeController.Theme {
  var name: String {
    switch self {
    case .purple:
      String(localized: "Dragonfruit")
    case .blue:
      String(localized: "Blueberry")
    case .orange:
      String(localized: "Mango")
    }
  }

  var color: Color {
    switch self {
    case .purple:
      return .lilacTint
    case .blue:
      return .marineTint
    case .orange:
      return .sunflowerTint
    }
  }

  var backgroundColor: Color {
    switch self {
    case .purple:
      return .lilacBackground
    case .blue:
      return .marineBackground
    case .orange:
      return .sunflowerBackground
    }
  }

  var appIcon: ImageResource {
    switch self {
    case .purple:
      return .bloomDisplayAppIconPurple
    case .blue:
      return .bloomDisplayAppIconBlue
    case .orange:
      return .bloomDisplayAppIconOrange
    }
  }

  var alternateIconName: String? {
    switch self {
    case .purple:
      "Dragonfruit"
    case .blue:
      nil
    case .orange:
      "Mango"
    }
  }
}

@MainActor @Observable
final class ThemeController {
  static let shared = ThemeController()

  private(set) var theme: Theme = .blue

  private init() {
    UserDefaults.group.register(defaults: [.Key.theme: Theme.blue.rawValue])
    
    // Migrate old theme names if needed
    if let rawTheme = UserDefaults.group.string(forKey: .Key.theme) {
      let migratedTheme: String
      switch rawTheme {
      case "ultramarine":
        migratedTheme = Theme.blue.rawValue
      case "lilac":
        migratedTheme = Theme.purple.rawValue
      case "sunflower":
        migratedTheme = Theme.orange.rawValue
      default:
        migratedTheme = rawTheme
      }
      
      // Save the migrated theme if it changed
      if migratedTheme != rawTheme {
        UserDefaults.group.set(migratedTheme, forKey: .Key.theme)
      }
      
      if let theme = Theme(rawValue: migratedTheme) {
        self.theme = theme
        Task {
          await set(theme: theme)
        }
      }
    }
  }

  func set(theme: ThemeController.Theme) async {
    let didChange = theme != self.theme
    self.theme = theme

    guard didChange else { return }

    UserDefaults.group.set(theme.rawValue, forKey: .Key.theme)

    await updateAppIconForTheme()

    // rawValue, not name: the display name is localized and would fragment the analytics.
    TelemetryDeck.signal("Updated Theme", parameters: ["selectedTheme": theme.rawValue])
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
