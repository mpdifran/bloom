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
    .init(serving: 1, foodItem: .Preview.grilledSalmon),
    .init(serving: 2, foodItem: .Preview.mixedLettuce),
    .init(serving: 1, foodItem: .Preview.cherryTomatoes),
    .init(serving: 1, foodItem: .Preview.slicedCarrots)
  ]
}
