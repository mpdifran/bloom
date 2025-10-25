//
//  MealRecordV29.swift
//  Bloom
//
//  Created by Claude on 2025-10-25.
//


import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV29 {
  @Model
  public final class MealRecord: Identifiable, Hashable {
    public var id: String = ""
    public var name: String = ""
    @Attribute(.externalStorage) public var imageData: Data? = nil

    @Relationship(inverse: \MealItemRecord.mealRecord)
    public var items: [MealItemRecord]? = []

    @Relationship(inverse: \FoodItemLog.mealItem)
    public var logs: [FoodItemLog]?

    public init(
      id: String = UUID().uuidString,
      name: String,
      imageData: Data?,
      items: [MealItemRecord]
    ) {
      self.id = id
      self.name = name
      self.imageData = imageData
      self.items = items
    }
  }
}
