//
//  MealRecordV6.swift
//  Supplements
//
//  Created by Zach Radford on 2025-01-18.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV6 {
  @Model
  public final class MealRecord: Identifiable, Hashable {
    public var id: String = ""
    public var name: String = ""
    @Relationship public var items: [MealItem] = []

    @Relationship(inverse: \FoodItemLog.mealItem)
    public var logs: [FoodItemLog]?

    init(
      id: String,
      name: String,
      items: [MealItem]
    ) {
      self.id = id
      self.name = name
      self.items = items
    }
  }
}
