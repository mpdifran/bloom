//
//  USDAFoodSearchRequest.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Vapor

struct USDAFoodSearchRequest: Content {
    let query: String
    let dataType: [String]
    let pageSize: Int
    let pageNumber: Int
    let sortBy: String
    let sortOrder: String
}
