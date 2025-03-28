//
//  FoodItemLog+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-01.
//

import Foundation
import SwiftUI

public extension SchemaV9.FoodItemLog {
  var hasSingleServing: Bool {
    foodItemServings?.count == 1
  }

  var firstFoodItemServing: SchemaV9.FoodItemServing? {
    foodItemServings?.first
  }
}
