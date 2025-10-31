//
//  GoalConfigurationIntent.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-30.
//

import AppIntents
import Foundation
import WidgetKit

struct GoalConfigurationIntent: WidgetConfigurationIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Goal Widget Configuration"
  nonisolated(unsafe) static var description = IntentDescription("Choose which goal to display in the widget.")

  @Parameter(title: "Goal")
  var goal: GoalEntity?

  static var parameterSummary: some ParameterSummary {
    Summary {
      \.$goal
    }
  }

  init() {
    self.goal = nil
  }

  init(goal: GoalEntity?) {
    self.goal = goal
  }

  var displayName: String {
    goal?.name ?? "Choose Goal"
  }
}
