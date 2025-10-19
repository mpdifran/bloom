//
//  TodayInsightConfigurationIntent.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-19.
//

import AppIntents
import Foundation
import WidgetKit

struct TodayInsightConfigurationIntent: WidgetConfigurationIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Today Insight Configuration"
  nonisolated(unsafe) static var description = IntentDescription("Configure which insight to display in the widget.")

  @Parameter(title: "Display Mode", default: .automatic)
  var displayMode: TodayInsightDisplayMode?

  static var parameterSummary: some ParameterSummary {
    Summary {
      \.$displayMode
    }
  }

  init() {
    self.displayMode = .automatic
  }

  init(displayMode: TodayInsightDisplayMode?) {
    self.displayMode = displayMode
  }
}

enum TodayInsightDisplayMode: String, AppEnum {
  case automatic
  case todaysAdvice
  case tonightsSleep

  static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Display Mode")

  static var caseDisplayRepresentations: [TodayInsightDisplayMode: DisplayRepresentation] = [
    .automatic: "Automatic (Time-based)",
    .todaysAdvice: "Today's Advice",
    .tonightsSleep: "Tonight's Sleep"
  ]
}
