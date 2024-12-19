//
//  NutritionUnitConverter.swift
//  Gardener
//
//  Created by Zach Radford on 2024-12-18.
//

import Foundation

struct NutritionUnitConverter {
  static func convert(
    _ value: Double?,
    from: NutritionUnit,
    to: NutritionUnit,
    type: NutrientType
  ) -> Double? {
    guard let value = value else { return nil }

    guard from != to else { return value } // already done

    // Conversion logic between units
    switch (from, to) {
    case (.grams, .milligrams):
      return value * 1000
    case (.milligrams, .grams):
      return value / 1000
    case (.milligrams, .micrograms):
      return value * 1000
    case (.micrograms, .milligrams):
      return value / 1000
    case (.grams, .micrograms):
      return value * 1_000_000
    case (.micrograms, .grams):
      return value / 1_000_000
    case (.grams, .percentDV):
      if let dailyValue = type.dailyValueAmount {
        return ((1000 * value) / dailyValue) * 100
      }
      return nil
    case (.milligrams, .percentDV):
      if let dailyValue = type.dailyValueAmount {
        return (value / dailyValue) * 100
      }
      return nil
    case (.micrograms, .percentDV):
      if let dailyValue = type.dailyValueAmount {
        return ((value / 1000) / dailyValue) * 100
      }
      return nil
    case (.percentDV, .grams):
      if let dailyValue = type.dailyValueAmount {
        return ((value / 100) * dailyValue) / 1000
      }
      return nil
    case (.percentDV, .milligrams):
      if let dailyValue = type.dailyValueAmount {
        return (value / 100) * dailyValue
      }
      return nil
    case (.percentDV, .micrograms):
      if let dailyValue = type.dailyValueAmount {
        return ((value / 100) * dailyValue) * 1000
      }
      return nil
    default: return value // unsupported cases
    }
  }
}
