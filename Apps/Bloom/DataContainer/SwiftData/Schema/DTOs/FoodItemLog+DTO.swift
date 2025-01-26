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
    public let foodItem: FoodItemDTO?

    public init(
        persistentID: PersistentIdentifier,
        id: String,
        date: Date,
        meal: FoodItemLog.Meal,
        numberOfServings: Double,
        foodItem: FoodItemDTO?
    ) {
        self.persistentID = persistentID
        self.id = id
        self.date = date
        self.meal = meal
        self.numberOfServings = numberOfServings
        self.foodItem = foodItem
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
            foodItem: foodItem?.asDTO()
        )
    }
}

public extension FoodItemLog {
  // This is a stop-gap while implementing Meals.
  // There is some additional work to assume a log can have multiple food items to make up a Meal
  // TODO: Zach - clean up once meals are implemented.
  var foodItem: FoodItemRecord? {
    foodItemServings?.first?.foodItem
  }
}
