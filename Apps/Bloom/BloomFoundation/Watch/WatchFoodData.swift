//
//  WatchFoodData.swift
//  BloomFoundation
//
//  Created by Claude on 2026-01-30.
//

import Foundation

// MARK: - Filter

/// Filter type for watch food list (matches iOS FoodItemHistoryTab)
public enum WatchFoodFilter: String, Codable, Sendable, CaseIterable {
  case frequent
  case recent
  case meals

  /// The raw value is the wire identifier and stays English; this is what the watch shows.
  public var displayName: String {
    switch self {
    case .frequent:
      String(localized: "Frequent", bundle: Bundle.bloomFoundation, comment: "Watch food list filter")
    case .recent:
      String(localized: "Recent", bundle: Bundle.bloomFoundation, comment: "Watch food list filter")
    case .meals:
      String(localized: "Meals", bundle: Bundle.bloomFoundation, comment: "Watch food list filter")
    }
  }
}

// MARK: - Meal

/// Meal type for watch food logging (matches iOS FoodItemLog.Meal)
public enum WatchMeal: String, Codable, Sendable, CaseIterable {
  case breakfast
  case lunch
  case dinner
  case snack

  /// The raw value is the wire identifier and stays English; this is what the watch shows.
  public var displayName: String {
    switch self {
    case .breakfast:
      String(localized: "Breakfast", bundle: Bundle.bloomFoundation, comment: "Meal name")
    case .lunch:
      String(localized: "Lunch", bundle: Bundle.bloomFoundation, comment: "Meal name")
    case .dinner:
      String(localized: "Dinner", bundle: Bundle.bloomFoundation, comment: "Meal name")
    case .snack:
      String(localized: "Snack", bundle: Bundle.bloomFoundation, comment: "Meal name")
    }
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

/// Data synced from iOS to watch containing foods per meal for quick logging.
public struct WatchFoodData: Codable, Sendable {
  // Frequent foods per meal
  public let breakfastFoods: [WatchFoodItem]
  public let lunchFoods: [WatchFoodItem]
  public let dinnerFoods: [WatchFoodItem]
  public let snackFoods: [WatchFoodItem]

  // Recent foods per meal
  public var recentBreakfastFoods: [WatchFoodItem]
  public var recentLunchFoods: [WatchFoodItem]
  public var recentDinnerFoods: [WatchFoodItem]
  public var recentSnackFoods: [WatchFoodItem]

  // Saved meals
  public var meals: [WatchMealItem]

  public let lastUpdated: Date

  public init(
    breakfastFoods: [WatchFoodItem],
    lunchFoods: [WatchFoodItem],
    dinnerFoods: [WatchFoodItem],
    snackFoods: [WatchFoodItem],
    recentBreakfastFoods: [WatchFoodItem] = [],
    recentLunchFoods: [WatchFoodItem] = [],
    recentDinnerFoods: [WatchFoodItem] = [],
    recentSnackFoods: [WatchFoodItem] = [],
    meals: [WatchMealItem] = [],
    lastUpdated: Date = Date()
  ) {
    self.breakfastFoods = breakfastFoods
    self.lunchFoods = lunchFoods
    self.dinnerFoods = dinnerFoods
    self.snackFoods = snackFoods
    self.recentBreakfastFoods = recentBreakfastFoods
    self.recentLunchFoods = recentLunchFoods
    self.recentDinnerFoods = recentDinnerFoods
    self.recentSnackFoods = recentSnackFoods
    self.meals = meals
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

  /// Returns the recent foods for the specified meal
  public func recentFoods(for meal: WatchMeal) -> [WatchFoodItem] {
    switch meal {
    case .breakfast: return recentBreakfastFoods
    case .lunch: return recentLunchFoods
    case .dinner: return recentDinnerFoods
    case .snack: return recentSnackFoods
    }
  }
}

// MARK: - Meal Item

/// Lightweight saved meal data for watch display
public struct WatchMealItem: Codable, Sendable, Identifiable, Hashable {
  public let id: String
  public let name: String
  public let calories: Double
  public let protein: Double
  public let carbs: Double
  public let fat: Double

  public init(
    id: String,
    name: String,
    calories: Double,
    protein: Double,
    carbs: Double,
    fat: Double
  ) {
    self.id = id
    self.name = name
    self.calories = calories
    self.protein = protein
    self.carbs = carbs
    self.fat = fat
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
  public let isVerified: Bool

  public init(
    id: String,
    name: String,
    brandName: String?,
    calories: Double,
    protein: Double,
    carbs: Double,
    fat: Double,
    servingName: String,
    isVerified: Bool = false
  ) {
    self.id = id
    self.name = name
    self.brandName = brandName
    self.calories = calories
    self.protein = protein
    self.carbs = carbs
    self.fat = fat
    self.servingName = servingName
    self.isVerified = isVerified
  }
}

// MARK: - Food Search Message

/// Message sent from watch to iOS to search for food items
public struct WatchFoodSearchMessage: Codable, Sendable {
  public static let messageType = "foodSearch"

  public let type: String
  public let query: String
  public let country: String

  public init(query: String, country: String = "usa") {
    self.type = Self.messageType
    self.query = query
    self.country = country
  }
}

/// Response from iOS containing food search results
public struct WatchFoodSearchResponse: Codable, Sendable {
  public let success: Bool
  public let foods: [WatchFoodItem]
  public let errorMessage: String?

  public init(success: Bool, foods: [WatchFoodItem] = [], errorMessage: String? = nil) {
    self.success = success
    self.foods = foods
    self.errorMessage = errorMessage
  }
}
