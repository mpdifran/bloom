//
//  MealItemRecordV29.swift
//  Bloom
//
//  Created by Claude on 2025-10-25.
//


import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV29 {
  @Model
  public final class MealItemRecord: Identifiable, Hashable {
    public var id: String = ""
    public var numberOfServings: Double = 0

    @Relationship public var foodItem: FoodItemRecord? = nil

    @Relationship public var mealRecord: MealRecord? = nil

    public init(
      id: String = UUID().uuidString,
      numberOfServings: Double,
      foodItem: FoodItemRecord?
    ) {
      self.id = id
      self.numberOfServings = numberOfServings
      self.foodItem = foodItem
    }
  }
}
