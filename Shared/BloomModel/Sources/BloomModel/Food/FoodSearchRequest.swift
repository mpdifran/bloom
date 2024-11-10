//
//  FoodSearchRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Foundation

public struct FoodSearchRequest: Codable {
    public let query: String?
    public let upcCode: String?

    public init(query: String?) {
        self.query = query
        self.upcCode = nil
    }

    public init(upcCode: String?) {
        self.query = nil
        self.upcCode = upcCode
    }
}
