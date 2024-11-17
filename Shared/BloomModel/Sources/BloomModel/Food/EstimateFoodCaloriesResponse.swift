//
//  FoodAutocompleteRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation


public struct EstimateFoodCaloriesResponse: Codable, Sendable {
    public let servings: [FoodItem]

    public init(servings: [FoodItem]) {
        self.servings = servings
    }
}
