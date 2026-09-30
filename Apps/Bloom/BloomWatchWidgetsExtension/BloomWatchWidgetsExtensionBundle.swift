//
//  BloomWatchWidgetsExtensionBundle.swift
//  BloomWatchWidgetsExtension
//
//  Created by Mark DiFranco on 2026-01-31.
//

import WidgetKit
import SwiftUI
import BloomFoundation

@main
struct BloomWatchWidgetsExtensionBundle: WidgetBundle {
  init() {
    CrashReporter.shared.install()
  }

  var body: some Widget {
    WorkoutWidget()
    ActionsWidget()
    BiologicalAgeWidget()
    HeartRateWidget()
    StepsWidget()
    ReminderWidget()
    WatchGoalWidget()
  }
}
