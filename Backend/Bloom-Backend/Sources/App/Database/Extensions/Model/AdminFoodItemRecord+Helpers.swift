//
//  AdminFoodItemRecord+Helpers.swift
//  Bloom-Backend
//
//  Created by Zach Radford on 2024-12-07.
//

import AdminBloomModel
import BloomModel
import Foundation

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
