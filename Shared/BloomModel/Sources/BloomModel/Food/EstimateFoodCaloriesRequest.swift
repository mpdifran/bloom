//
//  FoodAutocompleteRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation

public struct EstimateFoodCaloriesRequest: Codable, Sendable {
  public let foodImage: ImageFile?
  public let foodDescription: String?

  public init(
    foodImage: ImageFile,
    foodDescription: String?
  ) {
    self.foodImage = foodImage
    self.foodDescription = foodDescription
  }

  public init(
    foodDescription: String
  ) {
    self.foodImage = nil
    self.foodDescription = foodDescription
  }
}
