//
//  MealRecord.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-12.
//


import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV9 {
  @Model
  public final class MealRecord: Identifiable, Hashable {
    public var id: String = ""
    public var name: String = ""
    @Attribute(.externalStorage) public var imageData: Data? = nil

    @Relationship(inverse: \MealItemRecord.mealRecord)
    public var items: [MealItemRecord]? = []

    @Relationship(inverse: \FoodItemLog.mealItem)
    public var logs: [FoodItemLog]?

    init(
      id: String,
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
