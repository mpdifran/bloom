//
//  MealOption.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-16.
//

import AppIntents
import Foundation
import DataContainer

enum MealOption: String, AppEnum {
  case automatic = "automatic"
  case breakfast = "breakfast"
  case lunch = "lunch"
  case dinner = "dinner"
  case snack = "snack"

  nonisolated(unsafe) static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Meal")

  nonisolated(unsafe) static var caseDisplayRepresentations: [Self: DisplayRepresentation] = [
    .automatic: DisplayRepresentation(title: "Automatic (based on time)"),
    .breakfast: DisplayRepresentation(title: "Breakfast"),
    .lunch: DisplayRepresentation(title: "Lunch"),
    .dinner: DisplayRepresentation(title: "Dinner"),
    .snack: DisplayRepresentation(title: "Snack")
  ]

  func toMeal(at date: Date = Date()) -> FoodItemLog.Meal {
    switch self {
    case .automatic:
      let hour = Calendar.current.component(.hour, from: date)
      switch hour {
      case 6..<11:
        return .breakfast
      case 11..<16:
        return .lunch
      case 16..<24:
        return .dinner
      default:
        return .dinner
      }
    case .breakfast:
      return .breakfast
    case .lunch:
      return .lunch
    case .dinner:
      return .dinner
    case .snack:
      return .snack
    }
  }

  init(from meal: FoodItemLog.Meal) {
    switch meal {
    case .breakfast:
      self = .breakfast
    case .lunch:
      self = .lunch
    case .dinner:
      self = .dinner
    case .snack:
      self = .snack
    @unknown default:
      self = .automatic
    }
  }
}
