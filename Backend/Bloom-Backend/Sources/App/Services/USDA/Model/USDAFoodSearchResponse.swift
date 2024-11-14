//
//  USDAFoodSearchResponse.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Vapor

struct USDAFoodSearchResponse: Content {
    let foods: [USDAFoodItem]
}
