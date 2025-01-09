//
//  FoodSearchRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Foundation

public struct FoodSearchRequest: Codable, Sendable {
    public let name: String?
    public let brand: String?
    public let upcCode: String?
    public let country: FoodCountry?

    public init(
        name: String?,
        brand: String?,
        country: FoodCountry? = nil
    ) {
        self.name = name
        self.brand = brand
        self.upcCode = nil
        self.country = country
    }

    public init(
        upcCode: String?,
        country: FoodCountry? = nil
    ) {
        self.name = nil
        self.brand = nil
        self.upcCode = upcCode
        self.country = country
    }
}
