//
//  FoodItemRecord+Preview.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-26.
//

@preconcurrency import DataContainer

extension FoodItemRecord {
    enum Preview { }
}

extension FoodItemRecord.Preview {
    static let ritzCrackers = FoodItemRecord(
        id: .init("1234"),
        name: "Crackers",
        brandName: "Ritz",
        flavour: "Low Sodium",
        calories: 100,
        protein: 1,
        carbohydrates: 13,
        fat: 4.5,
        servingName: "6 crackers",
        servingUnitString: "g",
        servingValue: 20,
        ingredients: "Yogurt (Milk);  Rhubarb (8%);  Sugar;  Tapioca Starch;  Natural Flavourings;  Colour (Plain Caramel);  Stabiliser (Pectin);  Milk Minerals;  Cultures (Lactobacillus Bulgaricus;  Streptococcus Thermophilus;  Lactococcus Lactis;  Bifidobacterium Lactis (Bifidus Actiregularis®))",
        category: .branded,
        isVerified: true,
        logs: []
    )
}
