//
//  LogMealEntry.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-16.
//

import Foundation
import WidgetKit

struct LogMealEntry: TimelineEntry {
  let date: Date

  // Display fields
  let displayName: String
  let mealName: String
  let caloriesText: String?
  let proteinGrams: Double
  let carbsGrams: Double
  let fatGrams: Double
  let foodItemNames: String?
  let servingsDescription: String

  // Intent data for the button
  let intent: LogMealIntent
}
