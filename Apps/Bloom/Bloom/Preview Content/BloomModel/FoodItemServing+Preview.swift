//
//  FoodItemServing+Preview.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-05.
//

import BloomModel

extension FoodItemServingAmount {
    enum Preview { }
}

extension FoodItemServingAmount.Preview {

  static let grilledSalmonSalad: [FoodItemServingAmount] = [
    FoodItemServingAmount(serving: 1, foodItem: .Preview.grilledSalmon),
    FoodItemServingAmount(serving: 2, foodItem: .Preview.mixedLettuce),
    FoodItemServingAmount(serving: 1, foodItem: .Preview.cherryTomatoes),
    FoodItemServingAmount(serving: 1, foodItem: .Preview.slicedCarrots)
  ]
}
