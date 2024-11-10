//
//  FoodSearchRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Foundation

public struct FoodSearchRequest: Codable {
    public let name: String?
    public let brand: String?
    public let upcCode: String?

    public init(
        name: String?,
        brand: String?
    ) {
        self.name = name
        self.brand = brand
        self.upcCode = nil
    }

    public init(upcCode: String?) {
        self.name = nil
        self.brand = nil
        self.upcCode = upcCode
    }
}
