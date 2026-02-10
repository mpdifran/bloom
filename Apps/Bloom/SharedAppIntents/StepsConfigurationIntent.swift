//
//  StepsConfigurationIntent.swift
//  Bloom
//
//  Created by Claude Code on 2026-02-09.
//

import AppIntents
import Foundation
import WidgetKit

struct StepsConfigurationIntent: WidgetConfigurationIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Steps Widget Configuration"
  nonisolated(unsafe) static var description = IntentDescription("Choose the time period to display step data for.")

  @Parameter(title: "Time Period", default: .daily)
  var timePeriod: StepsWidgetTimePeriod

  static var parameterSummary: some ParameterSummary {
    Summary {
      \.$timePeriod
    }
  }

  init() {
    self.timePeriod = .daily
  }

  init(timePeriod: StepsWidgetTimePeriod) {
    self.timePeriod = timePeriod
  }
}
