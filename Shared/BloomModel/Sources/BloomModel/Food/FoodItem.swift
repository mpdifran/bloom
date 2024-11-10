//
//  Food.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Foundation
import AppFoundations

public final class FoodItemIdentifier: Identifier, Codable { }

public struct FoodItem: Codable {
    public let id: FoodItemIdentifier
    public let name: String
    public let brandName: String?
    public let serving: Quantity?
    public let ingredients: String?

    public init(
        id: FoodItemIdentifier,
        name: String,
        brandName: String?,
        serving: Quantity?,
        ingredients: String?
    ) {
        self.id = id
        self.name = name
        self.brandName = brandName
        self.serving = serving
        self.ingredients = ingredients
    }
}

public extension FoodItem {
    struct Quantity: Codable {
        public let value: Double
        public let unit: String

        public init(
            value: Double,
            unit: String
        ) {
            self.value = value
            self.unit = unit
        }
    }
}

public final class NutrientIdentifier: Identifier, Codable { }

public extension FoodItem {
    struct Nutrient: Codable {
        public let id: NutrientIdentifier
        public let name: String
        public let kind: Kind
        public let quantity: Quantity

        init(
            id: NutrientIdentifier,
            name: String,
            kind: Kind,
            quantity: Quantity
        ) {
            self.id = id
            self.name = name
            self.kind = kind
            self.quantity = quantity
        }
    }
}

public extension FoodItem.Nutrient {
    enum Kind: String, Codable {
        case protein
        case carbohydrates
        case fat
        case energy
    }
}
