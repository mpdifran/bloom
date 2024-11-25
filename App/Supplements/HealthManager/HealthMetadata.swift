//
//  HealthMetadata.swift
//  Supplements
//
//  Created by Zach Radford on 2024-11-24.
//

import Foundation
import HealthKit

// MARK: - HealthMetadata

enum HealthMetadata {
  case appIdentifier
  case meal(String)
  case food(String)

  var key: String {
    switch self {
    case .appIdentifier: "AppIdentifier"
    case .meal: "Meal"
    case .food: HKMetadataKeyFoodType
    }
  }

  var value: String {
    switch self {
    case .appIdentifier: Bundle.main.bundleIdentifier ?? "UnknownApp"
    case .meal(let mealName): mealName
    case .food(let foodName): foodName
    }
  }

  static func create(_ cases: [HealthMetadata]) -> [String: String] {
    Dictionary(uniqueKeysWithValues: cases.map { ($0.key, $0.value) })
  }

  static func predicate(for data: HealthMetadata) -> NSPredicate {
    HKQuery.predicateForObjects(
      withMetadataKey: data.key,
      allowedValues: [data.value]
    )
  }
}
