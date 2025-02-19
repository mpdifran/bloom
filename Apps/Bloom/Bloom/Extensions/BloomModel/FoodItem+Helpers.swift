//
//  FoodItem+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-02.
//

import BloomModel
import HealthKit

extension FoodItem.Quantity {

  var hkQuantity: HKQuantity {
    let unit = HKUnit(from: unit)
    return HKQuantity(unit: unit, doubleValue: value)
  }
}

extension FoodItem {

  func contains(searchQuery: String) -> Bool {
    name.localizedCaseInsensitiveContains(searchQuery) ||
    brandName?.localizedCaseInsensitiveContains(searchQuery) == true ||
    flavour?.localizedCaseInsensitiveContains(searchQuery) == true
  }
}
