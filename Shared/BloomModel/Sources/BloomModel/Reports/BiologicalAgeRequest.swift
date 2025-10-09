//
//  BiologicalAgeRequest.swift
//  bloom-model
//
//  Created by Assistant on 2025-09-14.
//

import Foundation

public struct BiologicalAgeRequest: Codable, Hashable, Sendable {
  public let healthContext: String // JSON blob of health data
  public let currentAge: Int? // User's chronological age from date of birth
  public let lastBiologicalAge: Double? // Previously calculated biological age

  public init(healthContext: String, currentAge: Int? = nil, lastBiologicalAge: Double? = nil) {
    self.healthContext = healthContext
    self.currentAge = currentAge
    self.lastBiologicalAge = lastBiologicalAge
  }
}
