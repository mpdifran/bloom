//
//  AdminFoodItemRecord.swift
//  bloom-model
//
//  Created by Zach Radford on 2024-12-01.
//

import Foundation

public struct AdminFoodItemRecord: Codable, Identifiable, Sendable, Hashable{
  public let id: FoodItemIdentifier
  public var name: String
  public var state: State
  public var brandName: String?
  public var flavour: String?
  public var category: Category
  public var barcode: String?
  public var nutritionLabelImage: String?
  public var packagingImage: String?
  public var ingredients: String?
  public var country: Country
  public var calories: Double?
  public var protein: Double?
  public var carbohydrates: Double?
  public var fat: Double?
  public var saturatedFat: Double?
  public var transFat: Double?
  public var polyunsaturatedFat: Double?
  public var monounsaturatedFat: Double?
  public var fiber: Double?
  public var sugar: Double?
  public var cholesterol: Double?
  public var sodium: Double?
  public var calcium: Double?
  public var iron: Double?
  public var potassium: Double?
  public var magnesium: Double?
  public var zinc: Double?
  public var vitaminA: Double?
  public var vitaminB6: Double?
  public var vitaminB12: Double?
  public var vitaminC: Double?
  public var vitaminD: Double?
  public var vitaminE: Double?
  public var servingName: String?
  public var servingValue: Double?
  public var servingUnit: String?
  public var downvoteCount: Int?
  public var source: String?
  /// Read-only.
  public var createdAt: Date?
  /// Read-only.
  public var updatedAt: Date?

  /// ID is the only field required to initialize, this is how we identify in the DB for updates.
  public init(id: FoodItemIdentifier) {
    self.id = id
  }
}

public extension AdminFoodItemRecord {
  enum State: String, Codable, Sendable {
    case unverified
    case verified
  }

  enum Category: String, Codable, Sendable {
    case generic
    case fastfood
    case restaurant
    case branded
  }

  enum Country: String, Codable, Sendable {
    case canada
    case usa
  }
}
