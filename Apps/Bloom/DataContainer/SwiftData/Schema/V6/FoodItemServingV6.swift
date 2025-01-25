//
//  FoodItemServingV6.swift
//  Supplements
//
//  Created by Zach Radford on 2025-01-19.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV6 {
  @Model
  public final class FoodItemServing: Identifiable, Hashable {
    public var id: String = ""
    public var numberOfServings: Double = 0

    @Relationship public var foodItem: FoodItemRecord? = nil

    @Relationship(inverse: \FoodItemLog.foodItemServings)
    public var foodItemLogs: FoodItemLog?

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
