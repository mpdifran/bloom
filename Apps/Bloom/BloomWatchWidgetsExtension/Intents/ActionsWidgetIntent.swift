//
//  ActionsWidgetIntent.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude on 2026-02-03.
//

import AppIntents
import Foundation
import WidgetKit

// MARK: - Configuration Intent

struct ActionsWidgetIntent: WidgetConfigurationIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Actions Widget"
  nonisolated(unsafe) static var description = IntentDescription("Choose which action to open.")

  @Parameter(title: "Action")
  var action: WatchActionEntity?

  static var parameterSummary: some ParameterSummary {
    Summary {
      \.$action
    }
  }

  init() {
    self.action = nil
  }

  init(action: WatchActionEntity?) {
    self.action = action
  }
}

// MARK: - Action Entity

struct WatchActionEntity: AppEntity {
  var id: String
  var name: String
  var systemImage: String
  var colorHex: String

  nonisolated(unsafe) static var typeDisplayRepresentation: TypeDisplayRepresentation = "Action"
  nonisolated(unsafe) static var defaultQuery = WatchActionEntityQuery()

  var displayRepresentation: DisplayRepresentation {
    let imageName: String
    switch id {
    case "food": imageName = "LogFoodIcon"
    case "drink": imageName = "LogWaterIcon"
    case "weight": imageName = "LogWeightIcon"
    case "bowelMovement": imageName = "LogBowelIcon"
    case "bloodPressure": imageName = "LogBloodPressureIcon"
    default:
      return DisplayRepresentation(
        title: "\(name)",
        image: DisplayRepresentation.Image(systemName: systemImage)
      )
    }
    return DisplayRepresentation(
      title: "\(name)",
      image: DisplayRepresentation.Image(named: imageName, isTemplate: true)
    )
  }
}

// MARK: - Entity Query

struct WatchActionEntityQuery: EntityQuery {
  // Available actions on the watch
  private static let availableActions: [WatchActionEntity] = [
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

  func entities(for identifiers: [String]) async throws -> [WatchActionEntity] {
    Self.availableActions.filter { identifiers.contains($0.id) }
  }

  func suggestedEntities() async throws -> [WatchActionEntity] {
    Self.availableActions
  }

  func defaultResult() async -> WatchActionEntity? {
    nil // Default to no action selected (shows generic plus icon)
  }
}
