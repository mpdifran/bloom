//
//  SubmitFoodItemIssueRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-01-27.
//

import Foundation

public struct SubmitFoodItemIssueRequest: Codable, Sendable {
  public let foodItemIssue: FoodItemIssue

  public init(foodItemIssue: FoodItemIssue) {
    self.foodItemIssue = foodItemIssue
  }
}
