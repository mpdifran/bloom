//
//  MealRecord+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-27.
//

import SwiftUI

public extension MealRecord {
  var image: UIImage? {
    guard let imageData else { return nil }

    return UIImage(data: imageData)
  }
}

public extension MealRecord {

  var totalCalories: Double {
    items?.reduce(0, { partialResult, item in
      partialResult + item.totalCalories
    }) ?? 0
  }

  var totalProtein: Double {
    items?.reduce(0, { partialResult, item in
      partialResult + item.totalProtein
    }) ?? 0
  }

  var totalCarbs: Double {
    items?.reduce(0, { partialResult, item in
      partialResult + item.totalCarbs
    }) ?? 0
  }

  var totalFat: Double {
    items?.reduce(0, { partialResult, item in
      partialResult + item.totalFat
    }) ?? 0
  }
}
