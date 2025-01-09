//
//  FoodAutocompleteResponse.swift
//  BloomModel
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation

public struct FoodAutocompleteResponse: Codable, Sendable {
    public let tokens: [String]

    public init(tokens: [String]) {
        self.tokens = tokens
    }
}
