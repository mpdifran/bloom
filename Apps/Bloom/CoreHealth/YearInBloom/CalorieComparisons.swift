//
//  CalorieComparisons.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-12.
//

import Foundation

/// Fun calorie comparisons for Year In Bloom
public enum CalorieComparison: CaseIterable, Sendable {
  case pizzaSlices
  case marathons
  case burgers
  case avocados
  case bananas
  case daysOfFood

  public var caloriesPerUnit: Double {
    switch self {
    case .pizzaSlices: return 285
    case .marathons: return 2600
    case .burgers: return 550
    case .avocados: return 240
    case .bananas: return 105
    case .daysOfFood: return 2000
    }
  }

  public var unitNameSingular: String {
    switch self {
    case .pizzaSlices: return "pizza slice"
    case .marathons: return "marathon"
    case .burgers: return "burger"
    case .avocados: return "avocado"
    case .bananas: return "banana"
    case .daysOfFood: return "day of food"
    }
  }

  public var unitNamePlural: String {
    switch self {
    case .pizzaSlices: return "pizza slices"
    case .marathons: return "marathons"
    case .burgers: return "burgers"
    case .avocados: return "avocados"
    case .bananas: return "bananas"
    case .daysOfFood: return "days of food"
    }
  }

  public var emoji: String {
    switch self {
    case .pizzaSlices: return "🍕"
    case .marathons: return "🏃"
    case .burgers: return "🍔"
    case .avocados: return "🥑"
    case .bananas: return "🍌"
    case .daysOfFood: return "🍽️"
    }
  }

  public func equivalentUnits(for calories: Double) -> Int {
    Int(calories / caloriesPerUnit)
  }

  public func unitName(for count: Int) -> String {
    count == 1 ? unitNameSingular : unitNamePlural
  }

  /// Generate a comparison string like "That's 500 pizza slices worth of energy!"
  public func comparisonText(for calories: Double) -> String {
    let units = equivalentUnits(for: calories)
    let name = unitName(for: units)
    return "\(emoji) That's \(units.formatted()) \(name) worth of energy!"
  }
}

// MARK: - Best Comparison Selection

public extension CalorieComparison {

  /// Select the best comparison that gives a nice readable number (between 10-500)
  static func bestComparison(for calories: Double) -> CalorieComparison {
    let comparisons = allCases.map { ($0, $0.equivalentUnits(for: calories)) }

    // Prefer values between 50-500 for best readability
    if let ideal = comparisons.first(where: { $0.1 >= 50 && $0.1 <= 500 }) {
      return ideal.0
    }

    // Fall back to values between 10-1000
    if let acceptable = comparisons.first(where: { $0.1 >= 10 && $0.1 <= 1000 }) {
      return acceptable.0
    }

    // Default to days of food as it scales well
    return .daysOfFood
  }

  /// Get the best comparison text for a calorie amount
  static func bestComparisonText(for calories: Double) -> String {
    bestComparison(for: calories).comparisonText(for: calories)
  }
}

// MARK: - Rolling Average Calculation

public extension Array where Element == Double {

  /// Calculate rolling average with given window size
  func rollingAverage(windowSize: Int) -> [Double] {
    guard count >= windowSize else { return self }

    var result = [Double]()
    for i in 0..<count {
      let startIndex = Swift.max(0, i - windowSize + 1)
      let window = Array(self[startIndex...i])
      let average = window.reduce(0, +) / Double(window.count)
      result.append(average)
    }
    return result
  }
}
