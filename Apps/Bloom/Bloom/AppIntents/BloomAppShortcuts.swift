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
      intent: OpenActionIntent(actionType: .scanFood),
      phrases: [
        "Scan food in \(.applicationName)",
        "Open scanner in \(.applicationName)",
        "Open food scanner in \(.applicationName)"
      ],
      shortTitle: "Scan Food",
      systemImageName: "barcode.viewfinder"
    )
  }
}
