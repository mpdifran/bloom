//
//  FoodCountry+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-14.
//

import BloomModel

extension FoodCountry {
  var country: FoodItemRecord.Country {
    switch self {
      case .canada: .canada
      case .usa: .usa
    }
  }
}
