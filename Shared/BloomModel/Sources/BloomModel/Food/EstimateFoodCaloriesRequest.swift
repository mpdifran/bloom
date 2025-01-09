//
//  FoodAutocompleteRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation

public struct EstimateFoodCaloriesRequest: Codable, Sendable {
    public let foodImage: ImageFile

    public init(foodImage: ImageFile) {
        self.foodImage = foodImage
    }
}
