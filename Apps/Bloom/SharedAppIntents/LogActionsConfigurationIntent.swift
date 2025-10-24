//
//  LogActionsConfigurationIntent.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-24.
//

import AppIntents
import Foundation
import WidgetKit

struct LogActionsConfigurationIntent: WidgetConfigurationIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Log Actions Configuration"
  nonisolated(unsafe) static var description = IntentDescription("Choose which health actions to display and their order.")

  @Parameter(
    title: "Actions",
    size: [
      .systemSmall: 2,
      .systemMedium: 4,
      .systemLarge: 8
    ]
  )
  var actions: [ActionEntity]?

  static var parameterSummary: some ParameterSummary {
    Summary {
      \.$actions
    }
  }

  init() {
    self.actions = Self.defaultActions
  }

  init(actions: [ActionEntity]?) {
    self.actions = actions
  }

  static var defaultActions: [ActionEntity] {
    [
      ActionEntity(actionType: .logFood),
      ActionEntity(actionType: .logWater),
      ActionEntity(actionType: .logWeight),
      ActionEntity(actionType: .logBloodPressure),
      ActionEntity(actionType: .logBowelMovement),
      ActionEntity(actionType: .logPeriod),
      ActionEntity(actionType: .barcodeScan),
      ActionEntity(actionType: .magicScan)
    ]
  }

  /// Get the configured actions - size is enforced by the parameter constraint
  func configuredActions(for family: WidgetFamily) -> [ActionType] {
    let selectedActions = actions ?? Self.defaultActions
    return selectedActions.map { $0.actionType }
  }
}
