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
        rawCountry: "canada",
        calories: 100,
        protein: 1,
        carbohydrates: 13,
        fat: 4.5,
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
        servingUnitString: "g",
        servingValue: 20,
        ingredients: "Yogurt (Milk);  Rhubarb (8%);  Sugar;  Tapioca Starch;  Natural Flavourings;  Colour (Plain Caramel);  Stabiliser (Pectin);  Milk Minerals;  Cultures (Lactobacillus Bulgaricus;  Streptococcus Thermophilus;  Lactococcus Lactis;  Bifidobacterium Lactis (Bifidus Actiregularis®))",
        category: .branded,
        isVerified: true,
        logs: []
    )
}
