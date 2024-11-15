//
//  USDAImportFoodResponse.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import Foundation
import Vapor

struct USDAImportFoodResponse: Content {
    let addedFoodItemsCount: Int
}
