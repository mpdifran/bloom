//
//  USDAImportFoodRequest.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import Vapor

struct USDAImportFoodRequest: Content {
    let kind: Kind
    let foods: [USDAImportFoodItem]
}

extension USDAImportFoodRequest {
    enum Kind: String, Codable{
        case foundation
    }
}
