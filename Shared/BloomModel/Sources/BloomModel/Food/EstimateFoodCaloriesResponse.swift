//
//  FoodAutocompleteRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation


public struct EstimateFoodCaloriesResponse: Codable, Sendable {
    public let servings: [Serving]

    public init(servings: [Serving]) {
        self.servings = servings
    }
}

extension EstimateFoodCaloriesResponse {
    public struct Serving: Codable, Sendable {
        let servings: Double
        let item: FoodItem

        public init(servings: Double, item: FoodItem) {
            self.servings = servings
            self.item = item
        }
    }
}
