//
//  NutritionUnit.swift
//  Gardener
//
//  Created by Zach Radford on 2024-12-18.
//

import Foundation

enum NutritionUnit {
  case calories
  case grams
  case milligrams
  case micrograms
  case percentDV

  var displayName: String {
    switch self {
    case .calories: "Cal"
    case .grams: "g"
    case .milligrams: "mg"
    case .micrograms: "µg"
    case .percentDV: "% DV"
    }
  }
}
