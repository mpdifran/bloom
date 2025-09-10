//
//  MarkItemsDistinctRequest.swift
//  AdminBloomModel
//
//  Created by Assistant on 2025-09-09.
//

import BloomModel
import Foundation

public struct MarkItemsDistinctRequest: Codable, Sendable {
  public let foodItemId: FoodItemIdentifier
  public let duplicateItemId: FoodItemIdentifier
  
  public init(
    foodItemId: FoodItemIdentifier,
    duplicateItemId: FoodItemIdentifier
  ) {
    self.foodItemId = foodItemId
    self.duplicateItemId = duplicateItemId
  }
}

public struct MarkItemsDistinctResponse: Codable, Sendable {
  public let success: Bool
  public let message: String
  
  public init(success: Bool, message: String) {
    self.success = success
    self.message = message
  }
}