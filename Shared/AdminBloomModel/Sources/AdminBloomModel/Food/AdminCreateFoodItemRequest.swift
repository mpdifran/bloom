//
//  AdminCreateFoodItemRequest.swift
//  admin-bloom-model
//
//  Created by Haocen Jiang on 2025-01-22.
//

import Foundation

public struct AdminCreateFoodItemRequest: Codable, Sendable {
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
