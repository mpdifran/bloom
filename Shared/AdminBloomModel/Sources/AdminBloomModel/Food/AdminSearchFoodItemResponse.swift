//
//  AdminSearchFoodItemResponse.swift
//  bloom-model
//
//  Created by Zach Radford on 2024-12-22.
//

import Foundation

public struct AdminSearchFoodItemResponse: Codable, Sendable {
  public let foodItemRecords: [AdminFoodItemRecord]

  public init(foodItemRecords: [AdminFoodItemRecord]) {
    self.foodItemRecords = foodItemRecords
  }
}
