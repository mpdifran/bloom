//
//  FoodAutocompleteRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation


public struct EstimateFoodCaloriesResponse: Codable, Sendable {
  public let name: String
  public let servings: [Serving]
  public let suggestedServings: [Serving]

  public init(
    name: String,
    servings: [Serving],
    suggestedServings: [Serving]
  ) {
    self.name = name
    self.servings = servings
    self.suggestedServings = suggestedServings
  }
}

extension EstimateFoodCaloriesResponse {
  public struct Serving: Codable, Sendable {
    public let servings: Double
    public let item: FoodItem

    public init(servings: Double, item: FoodItem) {
      self.servings = servings
      self.item = item
    }
  }
}
