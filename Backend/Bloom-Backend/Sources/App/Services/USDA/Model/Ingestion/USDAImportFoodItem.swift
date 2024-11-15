//
//  USDAImportFoodItem.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

struct USDAImportFoodItem: Codable {
    let description: String
    let foodNutrients: [FoodNutrient]
    let dataType: String
    let foodCategory: FoodCategory
    let fdcId: Int
    let foodPortions: [FoodPortion]
}

extension USDAImportFoodItem {
    struct FoodNutrient: Codable {
        let id: Int
        let nutrient: Nutrient
        let amount: Double?
    }

    struct Nutrient: Codable {
        let id: Int
        let name: String
        let unitName: String
    }

    struct FoodCategory: Codable {
        let description: String
    }

    struct FoodPortion: Codable {
        let id: Int
        let value: Double
        let measureUnit: MeasureUnit
        let modifier: String?
        let gramWeight: Double
        let amount: Double
    }

    struct MeasureUnit: Codable {
        let id: Int
        let name: String
        let abbreviation: String
    }
}
