//
//  ActionsWidget.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude on 2026-02-03.
//

import AppIntents
import CoreHealth
import SwiftUI
import WidgetKit

// MARK: - Timeline Provider

struct ActionsTimelineProvider: AppIntentTimelineProvider {
  typealias Entry = ActionsEntry
  typealias Intent = ActionsWidgetIntent

  func placeholder(in context: Context) -> ActionsEntry {
    ActionsEntry(date: .now, action: nil)
  }

  func snapshot(for configuration: ActionsWidgetIntent, in context: Context) async -> ActionsEntry {
    ActionsEntry(date: .now, action: configuration.action)
  }

  func timeline(for configuration: ActionsWidgetIntent, in context: Context) async -> Timeline<ActionsEntry> {
    // Static widget - never needs to refresh
    let entry = ActionsEntry(date: .now, action: configuration.action)
    return Timeline(entries: [entry], policy: .never)
  }

  /// Required for watchOS - provides pre-configured widget options since
  /// watchOS doesn't have an interactive configuration UI
  func recommendations() -> [AppIntentRecommendation<ActionsWidgetIntent>] {
    // Available actions on the watch
    let availableActions: [WatchActionEntity] = [
      WatchActionEntity(
        id: "food",
        name: String(localized: "Food", comment: "Name of a quick action on the watch"),
        systemImage: "fork.knife",
        colorHex: "3EC17D"
      ),
      WatchActionEntity(
        id: "drink",
        name: String(localized: "Drink", comment: "Name of a quick action on the watch"),
        systemImage: "waterbottle",
        colorHex: "6BB1D6"
      ),
      WatchActionEntity(
        id: "weight",
        name: String(localized: "Weight", comment: "Name of a quick action on the watch"),
        systemImage: "scalemass",
        colorHex: "7B68EE"
      ),
      WatchActionEntity(
        id: "bowelMovement",
        name: String(localized: "Bowel Movement", comment: "Name of a quick action on the watch"),
        systemImage: "toilet",
        colorHex: "A0522D"
      ),
      WatchActionEntity(
        id: "bloodPressure",
        name: String(localized: "Blood Pressure", comment: "Name of a quick action on the watch"),
        systemImage: "heart",
        colorHex: "FF6B6B"
      ),
      WatchActionEntity(
        id: "voice",
        name: String(localized: "Voice", comment: "Name of a quick action on the watch"),
        systemImage: "microphone.fill",
        colorHex: "EAAD63"
      )
    ]

    // First recommendation: generic actions (no specific action)
    var recommendations: [AppIntentRecommendation<ActionsWidgetIntent>] = [
      AppIntentRecommendation(intent: ActionsWidgetIntent(), description: "Actions")
    ]

    // Add recommendation for each specific action
    for action in availableActions {
      let intent = ActionsWidgetIntent(action: action)
      recommendations.append(AppIntentRecommendation(intent: intent, description: action.name))
    }

    return recommendations
  }
}

// MARK: - Timeline Entry

struct ActionsEntry: TimelineEntry {
  let date: Date
  let action: WatchActionEntity?

  var actionColor: Color {
    guard let hex = action?.colorHex else { return .blue }
    return Color(hex: hex) ?? .blue
  }

  var widgetURL: URL {
    if let actionId = action?.id {
      return URL(string: "bloom://watch/actions/\(actionId)")!
    }
    return URL(string: "bloom://watch/actions")!
  }
}

// MARK: - Widget

struct ActionsWidget: Widget {
  let kind = "ActionsWidget"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(kind: kind, intent: ActionsWidgetIntent.self, provider: ActionsTimelineProvider()) { entry in
      ActionsWidgetView(entry: entry)
        .containerBackground(.background.secondary, for: .widget)
        .widgetURL(entry.widgetURL)
    }
    .configurationDisplayName("Actions")
    .description("Quickly open actions or a specific action.")
    .supportedFamilies([.accessoryCircular, .accessoryCorner])
  }
}

// MARK: - Widget View

struct ActionsWidgetView: View {
  @Environment(\.widgetFamily) var family
  let entry: ActionsEntry

  private var isCorner: Bool { family == .accessoryCorner }

  var body: some View {
    ZStack {
      AccessoryWidgetBackground()
      content
    }
  }

  @ViewBuilder
  private var content: some View {
    if let action = entry.action {
      actionImage(for: action)
        .resizable()
        .scaledToFit()
        .frame(width: 20)
        .fontWeight(.medium)
        .foregroundStyle(entry.actionColor)
        .widgetAccentable()
    } else {
      Image(systemName: "plus")
        .font(.system(size: isCorner ? 22 : 30))
        .bold()
        .foregroundStyle(.blue)
        .widgetAccentable()
    }
  }

  private func actionImage(for action: WatchActionEntity) -> Image {
    switch action.id {
    case "food":
      return Image(.logFoodIcon).renderingMode(.template)
    case "drink":
      return Image(.logWaterIcon).renderingMode(.template)
    case "weight":
      return Image(.logWeightIcon).renderingMode(.template)
    case "bowelMovement":
      return Image(.logBowelIcon).renderingMode(.template)
    case "bloodPressure":
      return Image(.logBloodPressureIcon).renderingMode(.template)
    default:
      return Image(systemName: action.systemImage)
    }
  }
}

// MARK: - Color Extension

private extension Color {
  init?(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    guard hexSanitized.count == 6 else { return nil }

    var rgb: UInt64 = 0
    Scanner(string: hexSanitized).scanHexInt64(&rgb)

    let r = Double((rgb & 0xFF0000) >> 16) / 255.0
    let g = Double((rgb & 0x00FF00) >> 8) / 255.0
    let b = Double(rgb & 0x0000FF) / 255.0

    self.init(red: r, green: g, blue: b)
  }
}

// MARK: - Previews

#Preview("Circular - Default", as: .accessoryCircular) {
  ActionsWidget()
} timeline: {
  ActionsEntry(date: .now, action: nil)
}

#Preview("Circular - Food", as: .accessoryCircular) {
  ActionsWidget()
} timeline: {
  ActionsEntry(date: .now, action: WatchActionEntity(id: "food", name: "Food", systemImage: "fork.knife", colorHex: "3EC17D"))
}

#Preview("Circular - Weight", as: .accessoryCircular) {
  ActionsWidget()
} timeline: {
  ActionsEntry(date: .now, action: WatchActionEntity(id: "weight", name: "Weight", systemImage: "scalemass", colorHex: "7B68EE"))
}

#Preview("Circular - Voice", as: .accessoryCircular) {
  ActionsWidget()
} timeline: {
  ActionsEntry(date: .now, action: WatchActionEntity(id: "voice", name: "Voice", systemImage: "microphone.fill", colorHex: "EAAD63"))
}

#Preview("Corner - Default", as: .accessoryCorner) {
  ActionsWidget()
} timeline: {
  ActionsEntry(date: .now, action: nil)
}

#Preview("Corner - Food", as: .accessoryCorner) {
  ActionsWidget()
} timeline: {
  ActionsEntry(date: .now, action: WatchActionEntity(id: "food", name: "Food", systemImage: "fork.knife", colorHex: "3EC17D"))
}
