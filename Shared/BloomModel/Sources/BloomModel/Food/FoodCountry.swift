//
//  FoodCountry.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-19.
//

public enum FoodCountry: String, Codable, Identifiable, Sendable, Hashable, CaseIterable {
    public var id: Self { self }

    case canada
    case usa
}

public extension FoodCountry {

    var name: String {
        switch self {
        case .canada:
            "Canada"
        case .usa:
            "United States of America"
        }
    }
}
