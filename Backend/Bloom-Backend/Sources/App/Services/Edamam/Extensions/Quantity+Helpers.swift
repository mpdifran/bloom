//
//  Quantity+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Foundation
import BloomModel

extension Components.Schemas.Quantity {

    func asFoodItemQuantity() -> FoodItem.Quantity? {
        guard let label, let quantity else { return nil }

        return FoodItem.Quantity(value: quantity, unit: label)
    }
}
