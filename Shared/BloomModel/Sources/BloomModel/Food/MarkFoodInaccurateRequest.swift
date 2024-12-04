//
//  MarkFoodInaccurateRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-12-04.
//

import Foundation

public struct MarkFoodInaccurateRequest: Codable, Sendable {
  public let foodId: FoodItemIdentifier

  public init(foodId: FoodItemIdentifier) {
    self.foodId = foodId
  }
}
