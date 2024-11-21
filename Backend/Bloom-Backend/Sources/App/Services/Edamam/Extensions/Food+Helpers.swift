//
//  Food+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Foundation
import BloomModel

extension Components.Schemas.Food {

    var calories: Double? {
        nutrients?.additionalProperties["ENERC_KCAL"]
    }

    var protein: Double? {
        nutrients?.additionalProperties["PROCNT"]
    }

    var carbohydrates: Double? {
        nutrients?.additionalProperties["CHOCDF"]
    }

    var fat: Double? {
        nutrients?.additionalProperties["FAT"]
    }
}
