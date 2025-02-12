//
//  FoodItemLogV7.swift
//  Bloom
//
//  Created by Zach Radford on 2025-02-02.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV7 {
  @Model
  public final class FoodItemLog: Identifiable, Hashable {
    public var id: String = ""
    public var date: Date = Date.distantPast
    // TODO: Zach - delete this in V8 and use a helper to convert mealRawValue.
    public var meal: Meal = Meal.breakfast
    public var mealRawValue: String = Meal.breakfast.rawValue
    public var numberOfServings: Double = 0

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
      self.mealRawValue = meal.rawValue
      self.numberOfServings = numberOfServings
      self.foodItemServings = [
        FoodItemServing(
          id: UUID().uuidString,
          numberOfServings: 1,
          foodItem: foodItem
        )
      ]
    }

    public init(
      id: String,
      date: Date,
      meal: Meal,
      numberOfServings: Double,
      mealItem: MealRecord?
    ) {
      self.id = id
      self.date = date
      self.meal = meal
      self.mealRawValue = meal.rawValue
      self.numberOfServings = numberOfServings
      if let mealItem, let items = mealItem.items {
        self.foodItemServings = items.compactMap { mealItem in
          FoodItemServing(
            id: UUID().uuidString,
            numberOfServings: mealItem.numberOfServings,
            foodItem: mealItem.foodItem
          )
        }
      }
    }
  }
}

public extension SchemaV7.FoodItemLog {
  enum Meal: String, Hashable, Sendable, Codable, CaseIterable, Identifiable {
    public var id: Self { self }

    case breakfast
    case lunch
    case dinner
    case snack
  }
}
