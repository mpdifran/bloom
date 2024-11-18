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
        let servingCount: Int
        let item: FoodItem

        public init(servingCount: Int, item: FoodItem) {
            self.servingCount = servingCount
            self.item = item
        }
    }
}
