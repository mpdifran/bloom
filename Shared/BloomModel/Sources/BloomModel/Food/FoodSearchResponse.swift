//
//  FoodSearchResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Foundation

public struct FoodSearchResponse: Codable {
    public let foods: [FoodItem]

    public init(foods: [FoodItem]) {
        self.foods = foods
    }
}
