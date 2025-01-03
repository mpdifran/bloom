//
//  AdminUpdateFoodItemRequest.swift
//  bloom-model
//
//  Created by Zach Radford on 2024-12-07.
//

import Foundation

public struct AdminUpdateFoodItemRequest: Codable, Sendable {
  public let foodItemRecord: AdminFoodItemRecord
  public let nutritionLabelImage: ImageFile?
  public let packagingImage: ImageFile?

  public init(
    foodItemRecord: AdminFoodItemRecord,
    nutritionLabelImage: ImageFile?,
    packagingImage: ImageFile?
  ) {
    self.foodItemRecord = foodItemRecord
    self.nutritionLabelImage = nutritionLabelImage
    self.packagingImage = packagingImage
  }
}
