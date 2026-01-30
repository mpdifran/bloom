//
//  WatchFoodData.swift
//  BloomFoundation
//
//  Created by Claude on 2026-01-30.
//

import Foundation

// MARK: - Meal

/// Meal type for watch food logging (matches iOS FoodItemLog.Meal)
public enum WatchMeal: String, Codable, Sendable, CaseIterable {
  case breakfast
  case lunch
  case dinner
  case snack

  public var displayName: String {
    rawValue.capitalized
  }

  /// Returns the suggested meal based on the current time
  public static var suggested: WatchMeal {
    let hour = Calendar.current.component(.hour, from: Date())
    switch hour {
    case 6..<11: return .breakfast
    case 11..<16: return .lunch
    case 16..<24: return .dinner
    default: return .snack
    }
  }
}

// MARK: - Food Data

/// Data synced from iOS to watch containing frequent foods per meal for quick logging.
public struct WatchFoodData: Codable, Sendable {
  public let breakfastFoods: [WatchFoodItem]
  public let lunchFoods: [WatchFoodItem]
  public let dinnerFoods: [WatchFoodItem]
  public let snackFoods: [WatchFoodItem]
  public let lastUpdated: Date

  public init(
    breakfastFoods: [WatchFoodItem],
    lunchFoods: [WatchFoodItem],
    dinnerFoods: [WatchFoodItem],
    snackFoods: [WatchFoodItem],
    lastUpdated: Date = Date()
  ) {
    self.breakfastFoods = breakfastFoods
    self.lunchFoods = lunchFoods
    self.dinnerFoods = dinnerFoods
    self.snackFoods = snackFoods
    self.lastUpdated = lastUpdated
  }

  /// Returns the frequent foods for the specified meal
  public func foods(for meal: WatchMeal) -> [WatchFoodItem] {
    switch meal {
    case .breakfast: return breakfastFoods
    case .lunch: return lunchFoods
    case .dinner: return dinnerFoods
    case .snack: return snackFoods
    }
  }
}

/// Lightweight food item data for watch display
public struct WatchFoodItem: Codable, Sendable, Identifiable, Hashable {
  public let id: String
  public let name: String
  public let brandName: String?
  public let calories: Double
  public let protein: Double
  public let carbs: Double
  public let fat: Double
  public let servingName: String

  public init(
    id: String,
    name: String,
    brandName: String?,
    calories: Double,
    protein: Double,
    carbs: Double,
    fat: Double,
    servingName: String
  ) {
    self.id = id
    self.name = name
    self.brandName = brandName
    self.calories = calories
    self.protein = protein
    self.carbs = carbs
    self.fat = fat
    self.servingName = servingName
  }
}
