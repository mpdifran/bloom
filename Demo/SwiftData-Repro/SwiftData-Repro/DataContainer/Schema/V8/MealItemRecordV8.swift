//
//  MealItemRecord.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-12.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV8 {
  @Model
  public final class MealItemRecord: Identifiable, Hashable {
    public var id: String = ""
    public var numberOfServings: Double = 0

    @Relationship public var foodItem: FoodItemRecord?

    @Relationship public var mealRecord: MealRecord?

    init(
      id: String,
      numberOfServings: Double,
      foodItem: FoodItemRecord?
    ) {
      self.id = id
      self.numberOfServings = numberOfServings
      self.foodItem = foodItem
    }
  }
}
