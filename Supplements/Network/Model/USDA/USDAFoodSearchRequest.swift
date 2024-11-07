//
//  USDAFoodSearchRequest.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-06.
//

import Foundation

struct USDAFoodSearchRequest: Codable {
    let query: String
    let dataType: [String]
    let pageSize: Int
    let pageNumber: Int
    let sortBy: String
    let sortOrder: String
}
