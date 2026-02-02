//
//  WatchGoalWidgetIntent.swift
//  BloomWatchWidgetsExtension
//
//  Created by Claude on 2026-02-01.
//

import AppIntents
import BloomFoundation
import Foundation
import WidgetKit

// MARK: - Configuration Intent

struct WatchGoalWidgetIntent: WidgetConfigurationIntent {
  nonisolated(unsafe) static var title: LocalizedStringResource = "Goal Widget"
  nonisolated(unsafe) static var description = IntentDescription("Choose which goal to display.")

  @Parameter(title: "Goal")
  var goal: WatchGoalEntity?

  static var parameterSummary: some ParameterSummary {
    Summary {
      \.$goal
    }
  }

  init() {
    self.goal = nil
  }

  init(goal: WatchGoalEntity?) {
    self.goal = goal
  }
}

// MARK: - Goal Entity

struct WatchGoalEntity: AppEntity {
  var id: String
  var name: String
  var systemImage: String

  nonisolated(unsafe) static var typeDisplayRepresentation: TypeDisplayRepresentation = "Goal"
  nonisolated(unsafe) static var defaultQuery = WatchGoalEntityQuery()

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(name)",
      image: DisplayRepresentation.Image(systemName: systemImage)
    )
  }
}

// MARK: - Entity Query

struct WatchGoalEntityQuery: EntityQuery {
  private static let goalsKey = "WatchGoalProvider.goals"

  func entities(for identifiers: [String]) async throws -> [WatchGoalEntity] {
    let goals = loadCachedGoals()
    return goals.filter { identifiers.contains($0.id) }
  }

  func suggestedEntities() async throws -> [WatchGoalEntity] {
    return loadCachedGoals()
  }

  func defaultResult() async -> WatchGoalEntity? {
    return loadCachedGoals().first
  }

  private func loadCachedGoals() -> [WatchGoalEntity] {
    guard let data = UserDefaults.group.data(forKey: Self.goalsKey),
          let goals = try? JSONDecoder.watch.decode([WatchGoal].self, from: data) else {
      return []
    }

    return goals.map { goal in
      WatchGoalEntity(
        id: goal.id,
        name: goal.metricName,
        systemImage: goal.metricSystemImage
      )
    }
  }
}
