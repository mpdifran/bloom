//
//  UnverifiedFoodItemsResponse.swift
//  bloom-model
//
//  Created by Zach Radford on 2024-11-30.
//

import Foundation

public struct UnverifiedFoodItemsResponse: Codable, Sendable {
  public let foodItems: [FoodItem]

  public init(foodItems: [FoodItem]) {
    self.foodItems = foodItems
  }
}
