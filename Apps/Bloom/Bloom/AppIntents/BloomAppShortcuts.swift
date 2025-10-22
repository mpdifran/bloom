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
      intent: OpenActionIntent(actionType: .barcodeScan),
      phrases: [
        "Scan barcodes in \(.applicationName)",
        "Scan barcodes with \(.applicationName)",
        "Open barcode scanner with \(.applicationName)",
        "Open barcode scanner in \(.applicationName)"
      ],
      shortTitle: "Scan Barcodes",
      systemImageName: "barcode.viewfinder"
    )
    AppShortcut(
      intent: OpenActionIntent(actionType: .magicScan),
      phrases: [
        "Open magic scanner in \(.applicationName)",
        "Magic scan food in \(.applicationName)",
        "Scan food with \(.applicationName)",
        "Open food scanner with \(.applicationName)"
      ],
      shortTitle: "Scan Food",
      systemImageName: "camera.viewfinder"
    )
  }
}
