//
//  MealEntity.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-18.
//

import AppIntents
import Foundation
import DataContainer

struct MealEntity: AppEntity, Identifiable, Codable {
  let id: String
  let name: String

  var displayRepresentation: DisplayRepresentation {
    DisplayRepresentation(title: "\(name)")
  }

  nonisolated(unsafe) static var defaultQuery = MealQuery()
  nonisolated(unsafe) static var typeDisplayRepresentation: TypeDisplayRepresentation = "Saved Meal"
}

extension MealEntity {
  init(from mealDTO: MealRecordDTO) {
    self.id = mealDTO.id
    self.name = mealDTO.name
  }
}

struct MealQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [MealEntity] {
    let modelActor = MealRecordModelActor.standard()

    let allMeals = try await modelActor.fetchAllMealRecords()
    return allMeals
      .filter { identifiers.contains($0.id) }
      .map { MealEntity(from: $0) }
  }

  func suggestedEntities() async throws -> [MealEntity] {
    let modelActor = MealRecordModelActor.standard()

    let allMeals = try await modelActor.fetchAllMealRecords()
    return allMeals.map { MealEntity(from: $0) }
  }
}
