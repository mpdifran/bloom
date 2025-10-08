//
//  TrackFoodLogRequest.swift
//  bloom-model
//
//  Created by Claude Code on 2025-10-08.
//

import Foundation

public struct TrackFoodLogRequest: Codable, Sendable {
  public let foodIds: [FoodItemIdentifier]

  public init(foodIds: [FoodItemIdentifier]) {
    self.foodIds = foodIds
  }
}
