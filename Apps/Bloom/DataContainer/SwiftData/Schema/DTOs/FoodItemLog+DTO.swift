//
//  FoodItemLog+DTO.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import Foundation
import SwiftData

public struct FoodItemLogDTO: Sendable {
  public let persistentID: PersistentIdentifier
  public let id: String
  public let date: Date
  public let meal: FoodItemLog.Meal
  public let numberOfServings: Double
  public let foodItemServings: [FoodItemServingDTO]

  public init(
    persistentID: PersistentIdentifier,
    id: String,
    date: Date,
    meal: FoodItemLog.Meal,
    numberOfServings: Double,
    foodItemServings: [FoodItemServingDTO]
  ) {
    self.persistentID = persistentID
    self.id = id
    self.date = date
    self.meal = meal
    self.numberOfServings = numberOfServings
    self.foodItemServings = foodItemServings
  }
}

public extension FoodItemLog {

  func asDTO() -> FoodItemLogDTO {
    FoodItemLogDTO(
      persistentID: persistentModelID,
      id: id,
      date: date,
      meal: meal,
      numberOfServings: numberOfServings,
      foodItemServings: foodItemServings?.map { $0.asDTO() } ?? []
    )
  }
}

public extension FoodItemLogDTO {

  func totalNutrient(
    foodItem: FoodItemDTO,
    keyPath: KeyPath<FoodItemDTO, Double>
  ) -> Double {
    guard let serving = foodItemServings.first(where: { $0.foodItem?.id == foodItem.id }) else { return 0 }

    let value = foodItem[keyPath: keyPath]

    return numberOfServings * serving.numberOfServings * value
  }

  func totalNutrient(
    foodItem: FoodItemDTO,
    keyPath: KeyPath<FoodItemDTO, Double?>
  ) -> Double? {
    guard
      let serving = foodItemServings.first(where: { $0.foodItem?.id == foodItem.id }),
      let value = foodItem[keyPath: keyPath]
    else { return nil }

    return numberOfServings * serving.numberOfServings * value
  }
}
