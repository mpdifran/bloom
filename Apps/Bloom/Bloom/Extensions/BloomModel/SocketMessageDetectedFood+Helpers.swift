//
//  SocketMessageDetectedFood+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-13.
//

import BloomModel
import DataContainer

extension SocketMessage.DetectedFood.Meal {

  var asMeal: FoodItemLog.Meal {
    switch self {
    case .breakfast: .breakfast
    case .lunch: .lunch
    case .dinner: .dinner
    case .snack: .snack
    }
  }
}
