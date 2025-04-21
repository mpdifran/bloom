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
    let formattedUnit: String
    if unit == "cal" {
      formattedUnit = "Cal"
    } else {
      formattedUnit = unit
    }
    let hkUnit = HKUnit(from: formattedUnit)
    return HKQuantity(unit: hkUnit, doubleValue: value)
  }

  func doubleValue(for unit: HKUnit) -> Double {
    hkQuantity.doubleValue(for: unit)
  }
}

extension FoodItem {

  func contains(searchQuery: String) -> Bool {
    name.localizedCaseInsensitiveContains(searchQuery) ||
    brandName?.localizedCaseInsensitiveContains(searchQuery) == true ||
    flavour?.localizedCaseInsensitiveContains(searchQuery) == true
  }
}
