//
//  FoodItemLog.swift
//  Supplements
//
//  Created by Zach Radford on 2025-01-18.
//

import Foundation
import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV6 {
  @Model
  public final class FoodItemLog: Identifiable, Hashable {
    public var id: String = ""
    public var date: Date = Date.distantPast
    public var meal: Meal = Meal.breakfast
    public var numberOfServings: Double = 0

    @Relationship public var foodItem: SchemaV6.FoodItemRecord? = nil

    @Relationship public var mealItem: MealRecord? = nil

    @Relationship public var foodItemServings: [FoodItemServing]? = []

    public init(
      id: String,
      date: Date,
      meal: Meal,
      numberOfServings: Double,
      foodItem: FoodItemRecord?
    ) {
      self.id = id
      self.date = date
      self.meal = meal
      self.numberOfServings = numberOfServings
      self.foodItem = foodItem
    }
  }
}

public extension SchemaV6.FoodItemLog {
  enum Meal: String, Hashable, Sendable, Codable, CaseIterable, Identifiable {
    public var id: Self { self }

    case breakfast
    case lunch
    case dinner
    case snack
  }
}
