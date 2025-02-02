//
//  FoodItemLog+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-01.
//

import Foundation

public extension FoodItemLog.Meal {
  var name: String {
    rawValue.capitalized
  }
}
