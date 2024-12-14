//
//  FoodSearchResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Foundation

public struct FoodSearchResponse: Codable, Sendable {
    public let sections: [Section]

    public init(sections: [Section]) {
        self.sections = sections
    }
}

public extension FoodSearchResponse {
    public struct Section: Codable, Sendable {
        public let title: String
        public let index: Int
        public let category: FoodItem.Category
        public let foods: [FoodItem]

        public init(
            title: String,
            index: Int,
            category: FoodItem.Category,
            foods: [FoodItem]
        ) {
            self.title = title
            self.index = index
            self.category = category
            self.foods = foods
        }
    }
}
