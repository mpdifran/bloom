//
//  FoodAutocompleteRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation

public struct FoodAutocompleteRequest: Codable {
    public let query: String

    public init(query: String) {
        self.query = query
    }
}
