//
//  MagicScanStatusResponse.swift
//  bloom-model
//
//  Created by Claude on 2025-10-25.
//

import Foundation

public struct MagicScanStatusResponse: Codable, Sendable {
  public let results: [Result]

  public init(results: [Result]) {
    self.results = results
  }
}

extension MagicScanStatusResponse {
  public struct Result: Codable, Sendable {
    public let processingIdentifier: AIFoodProcessingIdentifier
    public let status: String
    public let servings: [Serving]?
    public let errorMessage: String?

    public init(
      processingIdentifier: AIFoodProcessingIdentifier,
      status: String,
      servings: [Serving]?,
      errorMessage: String?
    ) {
      self.processingIdentifier = processingIdentifier
      self.status = status
      self.servings = servings
      self.errorMessage = errorMessage
    }
  }

  public struct Serving: Codable, Sendable {
    public let servings: Double
    public let item: FoodItem

    public init(servings: Double, item: FoodItem) {
      self.servings = servings
      self.item = item
    }
  }
}
