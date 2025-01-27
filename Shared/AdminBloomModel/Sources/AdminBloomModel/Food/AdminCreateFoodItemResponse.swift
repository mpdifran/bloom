//
//  AdminCreateFoodItemResponse.swift
//  admin-bloom-model
//
//  Created by Haocen Jiang on 2025-01-22.
//

import Foundation

public struct AdminCreateFoodItemResponse: Codable, Sendable {
  public let foodItemRecord: AdminFoodItemRecord?

  public init(foodItemRecord: AdminFoodItemRecord?) {
    self.foodItemRecord = foodItemRecord
  }
}
