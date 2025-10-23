//
//  BloomAppShortcuts.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-21.
//

import AppIntents

struct BloomAppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: LogMealIntent(),
      phrases: [
        "Log a meal in \(.applicationName)",
        "Log food in \(.applicationName)",
        "Track food in \(.applicationName)"
      ],
      shortTitle: "Log Meal",
      systemImageName: "fork.knife"
    )
    AppShortcut(
      intent: OpenActionIntent(),
      phrases: [
        "\(\.$actionType) in \(.applicationName)",
        "\(\.$actionType) with \(.applicationName)"
      ],
      shortTitle: "Open Logger",
      systemImageName: "plus.circle.fill"
    )
    AppShortcut(
      intent: OpenVitalIntent(),
      phrases: [
        "View \(\.$vitalType) in \(.applicationName)",
        "Show \(\.$vitalType) in \(.applicationName)",
        "Open \(\.$vitalType) in \(.applicationName)"
      ],
      shortTitle: "View Vital",
      systemImageName: "figure"
    )
  }
}
