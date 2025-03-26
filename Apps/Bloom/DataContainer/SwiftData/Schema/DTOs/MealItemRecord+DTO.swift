//
//  MealItemRecord+DTO.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-26.
//

import Foundation
import SwiftData

public struct MealItemRecordDTO: Sendable, Equatable {
  public let persistentID: PersistentIdentifier
  public let id: String
  public let numberOfServings: Double
  public let foodItem: FoodItemDTO?
}

public extension MealItemRecord {

  func asDTO() -> MealItemRecordDTO {
    return MealItemRecordDTO(
      persistentID: persistentModelID,
      id: id,
      numberOfServings: numberOfServings,
      foodItem: foodItem?.asDTO()
    )
  }
}
