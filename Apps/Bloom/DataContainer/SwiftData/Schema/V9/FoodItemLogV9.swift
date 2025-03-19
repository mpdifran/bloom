//
//  FoodItemLogV8.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-12.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV9 {
  @Model
  public final class FoodItemLog: Identifiable, Hashable {
    public var id: String = ""
    public var name: String? = nil
    public var date: Date = Date.distantPast
    public var mealRawValue: String = Meal.breakfast.rawValue
    public var numberOfServings: Double = 0

    @Attribute(.externalStorage) public var imageData: Data? = nil

    @Relationship public var mealItem: MealRecord? = nil

    @Relationship public var foodItemServings: [FoodItemServing]? = []

    public init(
      id: String,
      name: String?,
      date: Date,
      meal: Meal,
      numberOfServings: Double,
      imageData: Data?,
      foodItemServings: [FoodItemServing]
    ) {
      self.id = id
      self.name = name
      self.date = date
      self.meal = meal
      self.numberOfServings = numberOfServings
      self.imageData = imageData
      self.foodItemServings = foodItemServings
    }

    @available(*, deprecated, message: "Use the initializer with foodItemServings instead.")
    public init(
      id: String,
      name: String?,
      date: Date,
      meal: Meal,
      numberOfServings: Double,
      imageData: Data?,
      foodItem: FoodItemRecord?
    ) {
      self.id = id
      self.name = name
      self.date = date
      self.meal = meal
      self.numberOfServings = numberOfServings
      self.imageData = imageData
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
      name: String?,
      date: Date,
      meal: Meal,
      numberOfServings: Double,
      imageData: Data?,
      mealItem: MealRecord?
    ) {
      self.id = id
      self.name = name
      self.date = date
      self.meal = meal
      self.numberOfServings = numberOfServings
      self.imageData = imageData
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

public extension SchemaV9.FoodItemLog {

  var meal: Meal {
    get {
      Meal(rawValue: mealRawValue) ?? .breakfast
    }
    set {
      mealRawValue = newValue.rawValue
    }
  }

  enum Meal: String, Hashable, Sendable, Codable, CaseIterable, Identifiable {
    public var id: Self { self }

    case breakfast
    case lunch
    case dinner
    case snack
  }
}
