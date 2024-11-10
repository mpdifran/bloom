//
//  FoodItem+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-10.
//

import BloomModel

extension FoodItem {

    var calories: Double? {
        nutrients.first(where: { $0.kind == .calories })?.quantity.value
    }
}
