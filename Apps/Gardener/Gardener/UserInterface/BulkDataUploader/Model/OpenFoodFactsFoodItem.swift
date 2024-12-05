//
//  OpenFoodFactsFoodItem.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-12-04.
//

import Foundation

struct OpenFoodFactsFoodItem: Codable {
    let id: String
    let productName: String?
    let brands: String?
    let quantity: String?
    let packaging: String?
    let categoriesTags: [String]?
//    let foodGroupsTags: [String]?
//    let traces: String?
//    let allergens: String?
//    let nutriscoreGrade: String?
//    let novaGroup: String?
//    let ecoscoreGrade: String?
    let nutritionData: NutritionData?
//    let nutriscoreData: NutriscoreData?
    let packagingTags: [String]?
    let languagesTags: [String]?
    let statesTags: [String]?
    let images: Images?

    struct Packaging: Codable {
        let material: String?
        let shape: String?
        let recycling: String?
        let numberOfUnits: Int?
        let quantityPerUnit: String?
    }

    struct NutritionData: Codable {
        let energy: Int?
        let fat: Double?
        let saturatedFat: Double?
        let sugars: Double?
        let salt: Double?
        let proteins: Double?
        let carbohydrates: Double?
    }

    struct NutriscoreData: Codable {
        let grade: String?
        let score: Int?
        let energyPoints: Int?
        let sugarsPoints: Int?
        let saturatedFatPoints: Int?
        let sodiumPoints: Int?
        let proteinsPoints: Int?
    }

    struct Images: Codable {
        let frontFr: ImageDetails?
        let ingredientsFr: ImageDetails?
        let nutritionFr: ImageDetails?

        struct ImageDetails: Codable {
            let imgid: String?
            let sizes: [String: ImageSize]?
        }

        struct ImageSize: Codable {
            let h: Int?
            let w: Int?
        }
    }
}
