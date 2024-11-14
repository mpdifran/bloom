//
//  USDAFoodItem.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Vapor

struct USDAFoodItem: Codable {
    let fdcId: Int
    let description: String?
    let foodCategory: String?
    let foodNutrients: [Nutrient]
}

extension USDAFoodItem {
    struct Nutrient: Codable {
        let nutrientId: Int
        let nutrientName: String
        let unitName: String
        let value: Double?
    }
}
