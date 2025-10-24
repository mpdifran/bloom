//
//  LogActionsTimelineProvider.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-24.
//

import Foundation
import WidgetKit

struct LogActionsTimelineProvider: AppIntentTimelineProvider {
  typealias Entry = LogActionsEntry
  typealias Intent = LogActionsConfigurationIntent

  func placeholder(in context: Context) -> LogActionsEntry {
    let maxCount = maxActionCount(for: context.family)
    return LogActionsEntry(
      date: Date(),
      actions: LogActionsConfigurationIntent.defaultActions.prefix(maxCount).map { $0.actionType }
    )
  }

  private func maxActionCount(for family: WidgetFamily) -> Int {
    switch family {
    case .systemSmall:
      return 2
    case .systemMedium:
      return 4
    case .systemLarge:
      return 8
    default:
      return 4
    }
  }

  func snapshot(for configuration: LogActionsConfigurationIntent, in context: Context) async -> LogActionsEntry {
    let actions = configuration.configuredActions(for: context.family)
    return LogActionsEntry(date: Date(), actions: actions)
  }

  func timeline(for configuration: LogActionsConfigurationIntent, in context: Context) async -> Timeline<LogActionsEntry> {
    let actions = configuration.configuredActions(for: context.family)
    let entry = LogActionsEntry(date: Date(), actions: actions)

    // Static timeline - actions don't change frequently
    // Update daily just in case configuration changes
    let nextUpdate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()

    return Timeline(entries: [entry], policy: .after(nextUpdate))
  }
}
