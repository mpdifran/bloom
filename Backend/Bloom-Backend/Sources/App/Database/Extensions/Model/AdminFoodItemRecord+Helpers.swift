//
//  AdminFoodItemRecord+Helpers.swift
//  Bloom-Backend
//
//  Created by Zach Radford on 2024-12-07.
//

import Foundation
import BloomModel

extension AdminFoodItemRecord.Category {
  func asCategory() -> FoodItemRecord.Category {
    switch self {
    case .generic: .generic
    case .fastfood: .fastfood
    case .restaurant: .restaurant
    case .branded: .branded
    }
  }
}

extension AdminFoodItemRecord.State {
  func asState() -> FoodItemRecord.State {
    switch self {
    case .needsAIProcessing: .needsAIProcessing
    case .unverified: .unverified
    case .needsMoreInfo: .needsMoreInfo
    case .verified: .verified
    }
  }
}

extension FoodItem.Country {
  func asCountry() -> FoodItemRecord.Country {
    switch self {
    case .canada: .canada
    case .usa: .usa
    }
  }
}
