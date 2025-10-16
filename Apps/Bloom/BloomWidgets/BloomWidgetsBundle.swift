//
//  BloomWidgetsBundle.swift
//  BloomWidgets
//
//  Created by Mark DiFranco on 2025-10-12.
//

import WidgetKit
import SwiftUI
internal import TelemetryDeck
internal import BloomFoundation

@main
struct BloomWidgetsBundle: WidgetBundle {
  init() {
    // Initialize TelemetryDeck to prevent crashes when AppIntents execute
    TelemetryDeck.initialize(
      config: TelemetryManagerConfiguration(
        appID: .telemetryDeckAppID,
        salt: "bloom_secret_salt"
      )
    )
  }

  var body: some Widget {
    ActionControl()
    LogMealWidget()
  }
}
