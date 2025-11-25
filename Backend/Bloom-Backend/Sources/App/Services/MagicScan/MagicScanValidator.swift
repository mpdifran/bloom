//
//  MagicScanValidator.swift
//  Bloom-Backend
//
//  Created by Claude Code on 2025-11-25.
//

import Foundation
import BloomModel
import Vapor

/// Validates magic scan nutrition estimates for physiological plausibility
struct MagicScanValidator {
  let logger: Logger

  init(logger: Logger) {
    self.logger = logger
  }

  /// Validates a list of servings and logs warnings for suspicious estimates
  func validate(servings: [MagicScanStatusResponse.Serving]) -> [String] {
    var warnings: [String] = []

    for serving in servings {
      let itemWarnings = validateServing(serving)
      warnings.append(contentsOf: itemWarnings)
    }

    // Log all warnings
    if !warnings.isEmpty {
      logger.warning("Magic scan validation warnings:\n\(warnings.joined(separator: "\n"))")
    }

    return warnings
  }

  private func validateServing(_ serving: MagicScanStatusResponse.Serving) -> [String] {
    var warnings: [String] = []
    let item = serving.item

    // Validate calorie-macro consistency
    if let calorieWarning = validateCalorieMacroConsistency(item: item) {
      warnings.append(calorieWarning)
    }

    // Validate serving size bounds
    if let servingSizeWarning = validateServingSize(item: item) {
      warnings.append(servingSizeWarning)
    }

    // Validate nutrient ratios
    if let nutrientRatioWarning = validateNutrientRatios(item: item) {
      warnings.append(nutrientRatioWarning)
    }

    return warnings
  }

  /// Validates that calories approximately equal 4×(protein+carbs) + 9×fat
  /// Allows ±15% tolerance
  private func validateCalorieMacroConsistency(item: FoodItem) -> String? {
    // Extract values in grams
    guard
      let calories = item.calories?.value,
      let proteinG = item.protein?.value,
      let carbsG = item.carbohydrates?.value,
      let fatG = item.fat?.value
    else {
      // Can't validate without all macros and calories
      return nil
    }

    // Calculate expected calories: 4 cal/g for protein and carbs, 9 cal/g for fat
    let expectedCalories = (proteinG * 4) + (carbsG * 4) + (fatG * 9)

    // Allow 15% tolerance
    let tolerance = expectedCalories * 0.15
    let difference = abs(calories - expectedCalories)

    if difference > tolerance {
      let percentDiff = (difference / expectedCalories) * 100
      return "⚠️ \(item.name): Calorie-macro mismatch - stated \(Int(calories)) kcal but macros suggest \(Int(expectedCalories)) kcal (±\(Int(percentDiff))%)"
    }

    return nil
  }

  /// Validates that serving sizes are within reasonable bounds
  /// Flags servings > 1000g or < 5g as suspicious
  private func validateServingSize(item: FoodItem) -> String? {
    guard let servingValue = item.servingQuantity?.value else {
      return nil
    }

    // Check for unreasonably large servings
    if servingValue > 1000 {
      return "⚠️ \(item.name): Unusually large serving size - \(Int(servingValue))g (>1kg)"
    }

    // Check for unreasonably small servings (except for very calorie-dense foods)
    if servingValue < 5, let calories = item.calories?.value, calories < 50 {
      return "⚠️ \(item.name): Unusually small serving size - \(Int(servingValue))g with \(Int(calories)) kcal"
    }

    return nil
  }

  /// Validates that nutrient ratios are within reasonable ranges
  private func validateNutrientRatios(item: FoodItem) -> String? {
    guard
      let proteinG = item.protein?.value,
      let carbsG = item.carbohydrates?.value,
      let fatG = item.fat?.value
    else {
      return nil
    }

    let totalMacros = proteinG + carbsG + fatG

    // Check if any single macro is > 95% of total (unlikely unless it's pure oil, protein powder, etc.)
    let proteinPercent = (proteinG / totalMacros) * 100
    let carbsPercent = (carbsG / totalMacros) * 100
    let fatPercent = (fatG / totalMacros) * 100

    if proteinPercent > 95 {
      return "⚠️ \(item.name): Unusually high protein ratio - \(Int(proteinPercent))%"
    }
    if carbsPercent > 95 {
      return "⚠️ \(item.name): Unusually high carb ratio - \(Int(carbsPercent))%"
    }
    if fatPercent > 95 {
      return "⚠️ \(item.name): Unusually high fat ratio - \(Int(fatPercent))%"
    }

    // Check for suspicious fat values in the sub-categories
    if let saturatedFat = item.saturatedFat?.value,
       saturatedFat > fatG * 1.1 {
      return "⚠️ \(item.name): Saturated fat (\(Int(saturatedFat))g) exceeds total fat (\(Int(fatG))g)"
    }

    return nil
  }
}
