//
//  OpenAIDetectFoodsResponse.swift
//  Bloom-Backend
//
//  Created by Claude Code on 2025-11-25.
//

import Foundation
import BloomModel

/// Response from OpenAI for food detection (Pass 1 of magic scan)
/// Contains only food names, brands, and serving counts - no nutrition data
struct OpenAIDetectFoodsResponse: Codable {
  let foodItems: [DetectedFood]
}

extension OpenAIDetectFoodsResponse {
  struct DetectedFood: Codable, Equatable, Sendable {
    let name: String
    let brandName: String?
    let servingCount: Double
  }
}
