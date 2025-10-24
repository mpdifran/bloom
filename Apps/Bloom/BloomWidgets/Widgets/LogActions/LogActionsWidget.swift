//
//  LogActionsWidget.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-24.
//

import SwiftUI
import WidgetKit
import BloomFoundation

struct LogActionsWidget: Widget {
  let kind: String = .WidgetKind.logActions

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: LogActionsConfigurationIntent.self,
      provider: LogActionsTimelineProvider()
    ) { entry in
      LogActionsWidgetView(entry: entry)
    }
    .configurationDisplayName("Log Data")
    .description("Quick access to health data logging actions.")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
  }
}

#Preview("Small - 2 Actions", as: .systemSmall) {
  LogActionsWidget()
} timeline: {
  LogActionsEntry(
    date: .now,
    actions: [.logFood, .logWater]
  )
}

#Preview("Medium - 4 Actions", as: .systemMedium) {
  LogActionsWidget()
} timeline: {
  LogActionsEntry(
    date: .now,
    actions: [.logFood, .logWater, .logWeight, .logBloodPressure]
  )
}

#Preview("Large - 8 Actions", as: .systemLarge) {
  LogActionsWidget()
} timeline: {
  LogActionsEntry(
    date: .now,
    actions: [
      .logFood,
      .logWater,
      .logWeight,
      .logBloodPressure,
      .logBowelMovement,
      .logPeriod,
      .barcodeScan,
      .magicScan
    ]
  )
}

#Preview("Large - Grey Actions", as: .systemLarge) {
  LogActionsWidget()
} timeline: {
  LogActionsEntry(
    date: .now,
    actions: [
      .barcodeScan,
      .magicScan,
      .logFood,
      .logWater,
      .logWeight,
      .logBloodPressure,
      .logBowelMovement,
      .logPeriod
    ]
  )
}
