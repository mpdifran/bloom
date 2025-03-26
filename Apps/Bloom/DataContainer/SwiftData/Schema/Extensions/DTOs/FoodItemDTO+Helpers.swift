//
//  FoodItemDTO+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-27.
//

import Foundation

public extension FoodItemDTO {

  /// The brand name, food name, and flavour combined into one string.
  var displayFullName: String {
    var result = [String]()

    if !brandName.isEmpty {
      result.append(brandName)
    }
    if !name.isEmpty {
      result.append(name)
    }
    if !flavour.isEmpty {
      result.append(flavour)
    }

    return result.joined(separator: " ")
  }
}
