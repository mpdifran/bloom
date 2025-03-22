//
//  FoodItemServing+DTO.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-22.
//

import Foundation
import SwiftData

public struct FoodItemServingDTO: Sendable {
  public let persistentID: PersistentIdentifier
  public let id: String
  public let numberOfServings: Double
  public let foodItem: FoodItemDTO?
}

public extension FoodItemServing {

  func asDTO() -> FoodItemServingDTO {
    FoodItemServingDTO(
      persistentID: persistentModelID,
      id: id,
      numberOfServings: numberOfServings,
      foodItem: foodItem?.asDTO()
    )
  }
}
