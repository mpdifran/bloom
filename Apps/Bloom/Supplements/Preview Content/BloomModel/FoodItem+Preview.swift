//
//  FoodItem+Preview.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-26.
//

import BloomModel

extension FoodItem {
    enum Preview { }
}

extension FoodItem.Preview {
    static let ritzCrackers = FoodItem(
        id: .init("1234"),
        name: "Crackers",
        brandName: "Ritz",
        flavour: "Low Sodium",
        country: .canada,
        calories: .init(value: 100, unit: "kcal"),
        protein: .init(value: 1, unit: "g"),
        carbohydrates: .init(value: 13, unit: "g"),
        fat: .init(value: 4.5, unit: "g"),
        saturatedFat: .init(value: 3, unit: "g"),
        transFat: .init(value: 1.5, unit: "g"),
        polyunsaturatedFat: nil,
        monounsaturatedFat: nil,
        fiber: .init(value: 4, unit: "g"),
        sugar: .init(value: 1, unit: "g"),
        cholesterol: nil,
        sodium: .init(value: 30, unit: "g"),
        calcium: nil,
        iron: nil,
        potassium: .init(value: 80, unit: "mg"),
        magnesium: nil,
        zinc: nil,
        vitaminA: .init(value: 0.358, unit: "mg"),
        vitaminB6: nil,
        vitaminB12: nil,
        vitaminC: nil,
        vitaminD: .init(value: 120, unit: "mg"),
        vitaminE: nil,
        servingName: "6 crackers",
        servingQuantity: .init(value: 20, unit: "g"),
        ingredients: "Yogurt (Milk);  Rhubarb (8%);  Sugar;  Tapioca Starch;  Natural Flavourings;  Colour (Plain Caramel);  Stabiliser (Pectin);  Milk Minerals;  Cultures (Lactobacillus Bulgaricus;  Streptococcus Thermophilus;  Lactococcus Lactis;  Bifidobacterium Lactis (Bifidus Actiregularis®))",
        category: .branded,
        isVerified: true
    )

    static let unverifiedRitzCrackers = FoodItem(
        id: .init("1234"),
        name: "Crackers",
        brandName: "Ritz",
        flavour: "Low Sodium",
        country: .canada,
        calories: .init(value: 100, unit: "kcal"),
        protein: .init(value: 1, unit: "g"),
        carbohydrates: .init(value: 13, unit: "g"),
        fat: .init(value: 4.5, unit: "g"),
        saturatedFat: nil,
        transFat: nil,
        polyunsaturatedFat: nil,
        monounsaturatedFat: nil,
        fiber: nil,
        sugar: nil,
        cholesterol: nil,
        sodium: nil,
        calcium: nil,
        iron: nil,
        potassium: nil,
        magnesium: nil,
        zinc: nil,
        vitaminA: nil,
        vitaminB6: nil,
        vitaminB12: nil,
        vitaminC: nil,
        vitaminD: nil,
        vitaminE: nil,
        servingName: "6 crackers",
        servingQuantity: .init(value: 20, unit: "g"),
        ingredients: "Yogurt (Milk);  Rhubarb (8%);  Sugar;  Tapioca Starch;  Natural Flavourings;  Colour (Plain Caramel);  Stabiliser (Pectin);  Milk Minerals;  Cultures (Lactobacillus Bulgaricus;  Streptococcus Thermophilus;  Lactococcus Lactis;  Bifidobacterium Lactis (Bifidus Actiregularis®))",
        category: .branded,
        isVerified: false
    )
}
