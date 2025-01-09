//
//  AdminUpdateFoodItemResponse.swift
//  bloom-model
//
//  Created by Zach Radford on 2024-12-07.
//

import Foundation

public struct AdminUpdateFoodItemResponse: Codable, Sendable {
  public let foodItemRecord: AdminFoodItemRecord?

  public init(foodItemRecord: AdminFoodItemRecord?) {
    self.foodItemRecord = foodItemRecord
  }
}
