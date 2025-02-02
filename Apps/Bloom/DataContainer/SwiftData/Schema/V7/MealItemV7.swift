//
//  MealItemV7.swift
//  Bloom
//
//  Created by Zach Radford on 2025-02-02.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV7 {
  @Model
  public final class MealItemRecord: Identifiable, Hashable {
    public var id: String = ""
    public var numberOfServings: Double = 0

    @Relationship public var foodItem: FoodItemRecord? = nil

    @Relationship public var mealRecord: MealRecord? = nil

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
