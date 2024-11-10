//
//  Food+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Foundation
import BloomModel

extension Components.Schemas.Food {

    func toNutrients() -> [FoodItem.Nutrient] {
        var result = [FoodItem.Nutrient]()

        if let value = nutrients?.additionalProperties["ENERC_KCAL"] {
            result.append(
                FoodItem.Nutrient(
                    name: "Calories",
                    kind: .calories,
                    quantity: .init(
                        value: value,
                        unit: "kcal"
                    )
                )
            )
        }
        if let value = nutrients?.additionalProperties["PROCNT"] {
            result.append(
                FoodItem.Nutrient(
                    name: "Protein",
                    kind: .protein,
                    quantity: .init(
                        value: value,
                        unit: "g"
                    )
                )
            )
        }
        if let value = nutrients?.additionalProperties["CHOCDF"] {
            result.append(
                FoodItem.Nutrient(
                    name: "Carbohydrates",
                    kind: .carbohydrates,
                    quantity: .init(
                        value: value,
                        unit: "g"
                    )
                )
            )
        }
        if let value = nutrients?.additionalProperties["FAT"] {
            result.append(
                FoodItem.Nutrient(
                    name: "Fat",
                    kind: .fat,
                    quantity: .init(
                        value: value,
                        unit: "g"
                    )
                )
            )
        }

        return result
    }
}
