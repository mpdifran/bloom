//
//  HabitDTO+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-26.
//

import Foundation
import DataContainer

extension HabitDTO {

  @MainActor
  var displayQuantity: String {
    quantity.displayString(for: unit)
  }
}
