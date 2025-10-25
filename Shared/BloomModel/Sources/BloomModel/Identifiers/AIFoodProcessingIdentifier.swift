//
//  AIFoodProcessingIdentifier.swift
//  bloom-model
//
//  Created by Claude on 2025-10-25.
//

import Foundation

public struct AIFoodProcessingIdentifier: Codable, Sendable, Hashable {
  public let value: String

  public init() {
    self.init("ai_food_\(UUID().uuidString)")
  }

  public init(_ value: String) {
    self.value = value
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.value = try container.decode(String.self)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}
