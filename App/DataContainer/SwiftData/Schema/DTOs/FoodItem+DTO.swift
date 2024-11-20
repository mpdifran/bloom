//
//  FoodItem+DTO.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-19.
//

import Foundation
import SwiftData

public struct FoodItemDTO: Sendable {
    public let persistentID: PersistentIdentifier
    public let id: String
    public let name: String
    public let brandName: String
    public let calories: Double
    public let protein: Double
    public let carbohydrates: Double
    public let fat: Double
    public let servingName: String?
    public let servingUnitString: String?
    public let servingValue: Double?
    public let ingredients: String?
    public let foodItemLogIDs: [String]

    public init(
        persistentID: PersistentIdentifier,
        id: String,
        name: String,
        brandName: String,
        calories: Double,
        protein: Double,
        carbohydrates: Double,
        fat: Double,
        servingName: String?,
        servingUnitString: String?,
        servingValue: Double?,
        ingredients: String?,
        foodItemLogIDs: [String]
    ) {
        self.persistentID = persistentID
        self.id = id
        self.name = name
        self.brandName = brandName
        self.calories = calories
        self.protein = protein
        self.carbohydrates = carbohydrates
        self.fat = fat
        self.servingName = servingName
        self.servingUnitString = servingUnitString
        self.servingValue = servingValue
        self.ingredients = ingredients
        self.foodItemLogIDs = foodItemLogIDs
    }
}

public extension FoodItem {

    func asDTO() -> FoodItemDTO {
        FoodItemDTO(
            persistentID: persistentModelID,
            id: id,
            name: name,
            brandName: brandName,
            calories: calories,
            protein: protein,
            carbohydrates: carbohydrates,
            fat: fat,
            servingName: servingName,
            servingUnitString: servingUnitString,
            servingValue: servingValue,
            ingredients: ingredients,
            foodItemLogIDs: logs.map({ $0.id })
        )
    }
}
