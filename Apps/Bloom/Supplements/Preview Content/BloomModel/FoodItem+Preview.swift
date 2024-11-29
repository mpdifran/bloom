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
        calories: .init(value: 100, unit: "kcal"),
        protein: .init(value: 1, unit: "g"),
        carbohydrates: .init(value: 13, unit: "g"),
        fat: .init(value: 4.5, unit: "g"),
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
        calories: .init(value: 100, unit: "kcal"),
        protein: .init(value: 1, unit: "g"),
        carbohydrates: .init(value: 13, unit: "g"),
        fat: .init(value: 4.5, unit: "g"),
        servingName: "6 crackers",
        servingQuantity: .init(value: 20, unit: "g"),
        ingredients: "Yogurt (Milk);  Rhubarb (8%);  Sugar;  Tapioca Starch;  Natural Flavourings;  Colour (Plain Caramel);  Stabiliser (Pectin);  Milk Minerals;  Cultures (Lactobacillus Bulgaricus;  Streptococcus Thermophilus;  Lactococcus Lactis;  Bifidobacterium Lactis (Bifidus Actiregularis®))",
        category: .branded,
        isVerified: false
    )
}
