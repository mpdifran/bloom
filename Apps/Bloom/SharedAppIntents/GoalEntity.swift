//
//  GoalEntity.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-30.
//

import AppIntents
import Foundation
import BloomFoundation

struct GoalEntity: AppEntity {
  var id: String
  var name: String

  nonisolated(unsafe) static var typeDisplayRepresentation: TypeDisplayRepresentation = "Goal"
  nonisolated(unsafe) static var defaultQuery = GoalEntityQuery()

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }
}

struct GoalEntityQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [GoalEntity] {
    // Load goals from UserDefaults cache
    let goals = loadCachedGoals()
    return goals.filter { identifiers.contains($0.id) }
  }

  func suggestedEntities() async throws -> [GoalEntity] {
    // Return all cached goals for selection
    return loadCachedGoals()
  }

  private func loadCachedGoals() -> [GoalEntity] {
    guard let data = UserDefaults.group.data(forKey: "GoalWidgetCache.AllGoals"),
          let goalIds = try? JSONDecoder().decode([String].self, from: data) else {
      return []
    }

    // Load each goal's data
    return goalIds.compactMap { goalId in
      guard let goalData = UserDefaults.group.data(forKey: "GoalWidgetCache.\(goalId)"),
            let decoded = try? JSONDecoder().decode(GoalWidgetDataCacheEntry.self, from: goalData) else {
        return nil
      }
      return GoalEntity(id: goalId, name: decoded.name)
    }
  }
}

// Helper struct for decoding just the name
private struct GoalWidgetDataCacheEntry: Codable {
  let name: String
}
