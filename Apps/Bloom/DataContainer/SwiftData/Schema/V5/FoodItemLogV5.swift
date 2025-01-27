//
//  FoodItemLogV5.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-02.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV5 {
  @Model
  public final class FoodItemLog: Identifiable, Hashable {
    public var id: String = ""
    public var date: Date = Date.distantPast
    public var meal: Meal = Meal.breakfast
    public var numberOfServings: Double = 0
    @Relationship public var foodItem: SchemaV5.FoodItemRecord? = nil

    public init(
      id: String,
      date: Date,
      meal: Meal,
      numberOfServings: Double,
      foodItem: SchemaV5.FoodItemRecord
    ) {
      self.id = id
      self.date = date
      self.meal = meal
      self.numberOfServings = numberOfServings
      self.foodItem = foodItem
    }
  }
}

public extension SchemaV5.FoodItemLog {
  enum Meal: String, Hashable, Sendable, Codable, CaseIterable, Identifiable {
    public var id: Self { self }

    case breakfast
    case lunch
    case dinner
    case snack
  }
}

public extension SchemaV5.FoodItemLog.Meal {
  var name: String {
    rawValue.capitalized
  }
}

extension SchemaV5.FoodItemLog.Meal {

  func toV6() -> SchemaV6.FoodItemLog.Meal {
    switch self {
    case .breakfast: return .breakfast
    case .lunch: return .lunch
    case .dinner: return .dinner
    case .snack: return .snack
    }
  }
}
