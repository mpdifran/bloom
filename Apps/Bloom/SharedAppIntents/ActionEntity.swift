//
//  ActionEntity.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-24.
//

import AppIntents
import Foundation
import SFSafeSymbols

struct ActionEntity: AppEntity {
  nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Health Action")

  var id: String
  var actionType: ActionType

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(
      title: "\(actionType.label)",
      image: DisplayRepresentation.Image(systemName: actionType.sfSymbol.rawValue)
    )
  }

  nonisolated(unsafe) static var defaultQuery = ActionEntityQuery()

  init(actionType: ActionType) {
    self.id = actionType.rawValue
    self.actionType = actionType
  }
}

struct ActionEntityQuery: EntityQuery {
  func entities(for identifiers: [ActionEntity.ID]) async throws -> [ActionEntity] {
    identifiers.compactMap { id in
      guard let actionType = ActionType(rawValue: id) else { return nil }
      return ActionEntity(actionType: actionType)
    }
  }

  func suggestedEntities() async throws -> [ActionEntity] {
    ActionType.allCases.map { ActionEntity(actionType: $0) }
  }
}
