//
//  FoodItemRecord+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-22.
//

import DataContainer
import BloomModel

extension FoodItemRecord {

    convenience init(foodItem: FoodItem) {
        self.init(
            id: foodItem.id.value,
            name: foodItem.name,
            brandName: foodItem.brandName ?? "",
            flavour: foodItem.flavour ?? "",
            rawCountry: foodItem.country?.rawValue,
            calories: foodItem.calories?.value ?? 0,
            protein: foodItem.protein?.value ?? 0,
            carbohydrates: foodItem.carbohydrates?.value ?? 0,
            fat: foodItem.fat?.value ?? 0,
            saturatedFat: foodItem.saturatedFat?.value,
            transFat: foodItem.transFat?.value,
            polyunsaturatedFat: foodItem.polyunsaturatedFat?.value,
            monounsaturatedFat: foodItem.monounsaturatedFat?.value,
            fiber: foodItem.fiber?.value,
            sugar: foodItem.sugar?.value,
            cholesterol: foodItem.cholesterol?.value,
            sodium: foodItem.sodium?.value,
            calcium: foodItem.calcium?.value,
            iron: foodItem.iron?.value,
            potassium: foodItem.potassium?.value,
            magnesium: foodItem.magnesium?.value,
            zinc: foodItem.zinc?.value,
            vitaminA: foodItem.vitaminA?.value,
            vitaminB6: foodItem.vitaminB6?.value,
            vitaminB12: foodItem.vitaminB12?.value,
            vitaminC: foodItem.vitaminC?.value,
            vitaminD: foodItem.vitaminD?.value,
            vitaminE: foodItem.vitaminE?.value,
            servingName: foodItem.servingName,
            servingUnitString: foodItem.servingQuantity?.unit,
            servingValue: foodItem.servingQuantity?.value,
            ingredients: foodItem.ingredients,
            category: .init(rawValue: foodItem.category.rawValue),
            isVerified: foodItem.isVerified,
            logs: []
        )
    }
}

extension FoodItemRecord {

    func asNetworkFoodItem() -> FoodItem {
        let quantity: FoodItem.Quantity?
        if let servingValue, let servingUnitString {
            quantity = .init(
                value: servingValue,
                unit: servingUnitString
            )
        } else {
            quantity = nil
        }

        return FoodItem(
            id: .init(id),
            name: name,
            brandName: brandName,
            flavour: flavour,
            country: FoodItem.Country(rawValue: rawCountry ?? ""),
            calories: .init(value: calories, unit: "kcal"),
            protein: .init(value: protein, unit: "g"),
            carbohydrates: .init(value: carbohydrates, unit: "g"),
            fat: .init(value: fat, unit: "g"),
            saturatedFat: saturatedFat.map({ .init(value: $0, unit: "g") }),
            transFat: transFat.map({ .init(value: $0, unit: "g") }),
            polyunsaturatedFat: polyunsaturatedFat.map({ .init(value: $0, unit: "g") }),
            monounsaturatedFat: monounsaturatedFat.map({ .init(value: $0, unit: "g") }),
            fiber: fiber.map({ .init(value: $0, unit: "g") }),
            sugar: sugar.map({ .init(value: $0, unit: "g") }),
            cholesterol: cholesterol.map({ .init(value: $0, unit: "mg") }),
            sodium: sodium.map({ .init(value: $0, unit: "mg") }),
            calcium: calcium.map({ .init(value: $0, unit: "mg") }),
            iron: iron.map({ .init(value: $0, unit: "mg") }),
            potassium: potassium.map({ .init(value: $0, unit: "mg") }),
            magnesium: magnesium.map({ .init(value: $0, unit: "mg") }),
            zinc: zinc.map({ .init(value: $0, unit: "mg") }),
            vitaminA: vitaminA.map({ .init(value: $0, unit: "mg") }),
            vitaminB6: vitaminB6.map({ .init(value: $0, unit: "mg") }),
            vitaminB12: vitaminB12.map({ .init(value: $0, unit: "mg") }),
            vitaminC: vitaminC.map({ .init(value: $0, unit: "mg") }),
            vitaminD: vitaminD.map({ .init(value: $0, unit: "mg") }),
            vitaminE: vitaminE.map({ .init(value: $0, unit: "mg") }),
            servingName: servingName,
            servingQuantity: quantity,
            ingredients: ingredients,
            category: networkCategory,
            isVerified: isVerified
        )
    }

    var networkCategory: FoodItem.Category {
        guard let dbCategory = self.category else { return .generic }

        return FoodItem.Category(rawValue: dbCategory.rawValue) ?? .generic
    }
}
