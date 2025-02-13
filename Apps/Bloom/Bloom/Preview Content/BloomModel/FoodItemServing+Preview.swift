//
//  FoodItemServing+Preview.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-05.
//

import BloomModel

extension FoodItemServing {
    enum Preview { }
}

extension FoodItemServing.Preview {

  static let grilledSalmonSalad: [FoodItemServing] = [
    FoodItemServing(serving: 1, foodItem: .Preview.grilledSalmon),
    FoodItemServing(serving: 2, foodItem: .Preview.mixedLettuce),
    FoodItemServing(serving: 1, foodItem: .Preview.cherryTomatoes),
    FoodItemServing(serving: 1, foodItem: .Preview.slicedCarrots)
  ]
}
