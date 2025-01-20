//
//  USDAFoodSearchResponse.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-06.
//

import Foundation

struct USDAFoodSearchResponse: Codable {
    let totalHits: Int
    let currentPage: Int
    let totalPages: Int
    let pageList: [Int]
    let foods: [USDAFood]
}

struct USDAFood: Codable, Identifiable {
    var id: Int { fdcId }
    let fdcId: Int
//    let description: String
//    let dataType: String
//    let gtinUpc: String
//    let publishedDate: String
    let brandOwner: String?
    let brandName: String?
//    let ingredients: String
//    let marketCountry: String
//    let foodCategory: String
//    let modifiedDate: String
//    let dataSource: String
//    let packageWeight: String
//    let servingSizeUnit: String
//    let servingSize: Double
//    let householdServingFullText: String
//    let tradeChannels: [String]
//    let allHighlightFields: String
//    let score: Double
//    let microbes: [String]
    let foodNutrients: [FoodNutrient]
//    let finalFoodInputFoods: [String]
//    let foodMeasures: [String]
//    let foodAttributes: [String]
//    let foodAttributeTypes: [String]
//    let foodVersionIds: [String]
}

struct FoodNutrient: Codable {
    let nutrientId: Int
    let nutrientName: String
    let nutrientNumber: String
    let unitName: String
    let value: Double
    let rank: Int
    let indentLevel: Int
    let foodNutrientId: Int
    let percentDailyValue: Double?
}
