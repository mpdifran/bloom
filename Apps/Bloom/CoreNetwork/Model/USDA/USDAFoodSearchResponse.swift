//
//  USDAFoodSearchResponse.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-06.
//

import Foundation

public struct USDAFoodSearchResponse: Codable {
    public let totalHits: Int
    public let currentPage: Int
    public let totalPages: Int
    public let pageList: [Int]
    public let foods: [USDAFood]

    public init(
        totalHits: Int,
        currentPage: Int,
        totalPages: Int,
        pageList: [Int],
        foods: [USDAFood]
    ) {
        self.totalHits = totalHits
        self.currentPage = currentPage
        self.totalPages = totalPages
        self.pageList = pageList
        self.foods = foods
    }
}

public struct USDAFood: Codable, Identifiable {
    public var id: Int { fdcId }
    public let fdcId: Int
//    let description: String
//    let dataType: String
//    let gtinUpc: String
//    let publishedDate: String
    public let brandOwner: String?
    public let brandName: String?
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
    public let foodNutrients: [FoodNutrient]
//    let finalFoodInputFoods: [String]
//    let foodMeasures: [String]
//    let foodAttributes: [String]
//    let foodAttributeTypes: [String]
//    let foodVersionIds: [String]

    public init(
        fdcId: Int,
        brandOwner: String?,
        brandName: String?,
        foodNutrients: [FoodNutrient]
    ) {
        self.fdcId = fdcId
        self.brandOwner = brandOwner
        self.brandName = brandName
        self.foodNutrients = foodNutrients
    }
}

public struct FoodNutrient: Codable {
    public let nutrientId: Int
    public let nutrientName: String
    public let nutrientNumber: String
    public let unitName: String
    public let value: Double
    public let rank: Int
    public let indentLevel: Int
    public let foodNutrientId: Int
    public let percentDailyValue: Double?

    public init(
        nutrientId: Int,
        nutrientName: String,
        nutrientNumber: String,
        unitName: String,
        value: Double,
        rank: Int,
        indentLevel: Int,
        foodNutrientId: Int,
        percentDailyValue: Double?
    ) {
        self.nutrientId = nutrientId
        self.nutrientName = nutrientName
        self.nutrientNumber = nutrientNumber
        self.unitName = unitName
        self.value = value
        self.rank = rank
        self.indentLevel = indentLevel
        self.foodNutrientId = foodNutrientId
        self.percentDailyValue = percentDailyValue
    }
}
