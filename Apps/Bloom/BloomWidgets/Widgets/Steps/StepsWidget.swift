//
//  StepsWidget.swift
//  BloomWidgets
//
//  Created by Claude Code on 2026-02-09.
//

import BloomFoundation
import SwiftUI
import WidgetKit

struct StepsWidget: Widget {
  let kind: String = .WidgetKind.steps

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: StepsConfigurationIntent.self,
      provider: StepsTimelineProvider()
    ) { entry in
      StepsWidgetView(entry: entry)
    }
    .configurationDisplayName("Steps")
    .description("Track your steps and walking distance.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

// MARK: - Previews

#Preview("Daily - Small", as: .systemSmall) {
  StepsWidget()
} timeline: {
  StepsEntry.placeholder(for: .daily)
}

#Preview("Daily - Medium", as: .systemMedium) {
  StepsWidget()
} timeline: {
  StepsEntry.placeholder(for: .daily)
}

#Preview("Weekly - Small", as: .systemSmall) {
  StepsWidget()
} timeline: {
  StepsEntry.placeholder(for: .weekly)
}

#Preview("Weekly - Medium", as: .systemMedium) {
  StepsWidget()
} timeline: {
  StepsEntry.placeholder(for: .weekly)
}

#Preview("Monthly - Small", as: .systemSmall) {
  StepsWidget()
} timeline: {
  StepsEntry.placeholder(for: .monthly)
}

#Preview("Monthly - Medium", as: .systemMedium) {
  StepsWidget()
} timeline: {
  StepsEntry.placeholder(for: .monthly)
}

#Preview("Yearly - Small", as: .systemSmall) {
  StepsWidget()
} timeline: {
  StepsEntry.placeholder(for: .yearly)
}

#Preview("Yearly - Medium", as: .systemMedium) {
  StepsWidget()
} timeline: {
  StepsEntry.placeholder(for: .yearly)
}

#Preview("No Data - Small", as: .systemSmall) {
  StepsWidget()
} timeline: {
  StepsEntry.empty(for: .daily)
}

#Preview("No Data - Medium", as: .systemMedium) {
  StepsWidget()
} timeline: {
  StepsEntry.empty(for: .daily)
}
