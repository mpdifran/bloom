//
//  MealItemV6.swift
//  Supplements
//
//  Created by Zach Radford on 2025-01-18.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV6 {
  @Model
  public final class MealItem: Identifiable, Hashable {
    public var id: String = ""
    public var numberOfServings: Double = 0

    @Relationship public var foodItem: FoodItemRecord? = nil

    @Relationship(deleteRule: .cascade, inverse: \MealRecord.items)
    public var mealRecord: MealRecord? = nil

    init(
      id: String,
      numberOfServings: Double,
      foodItem: FoodItemRecord?,
      mealRecord: MealRecord?
    ) {
      self.id = id
      self.numberOfServings = numberOfServings
      self.foodItem = foodItem
      self.mealRecord = mealRecord
    }
  }
}
