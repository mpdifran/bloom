//
//  BiologicalAgeRequest.swift
//  bloom-model
//
//  Created by Assistant on 2025-09-14.
//

import Foundation

public struct BiologicalAgeRequest: Codable, Hashable, Sendable {
  public let healthContext: String // JSON blob of health data
  public let chronologicalAge: Int // User's actual age
  public let previousBiologicalAge: Double? // Previously calculated biological age
  public let previousPositiveFactors: [String] // Positive factors from previous calculation
  public let previousNegativeFactors: [String] // Negative factors from previous calculation

  public init(
    healthContext: String,
    chronologicalAge: Int,
    previousBiologicalAge: Double? = nil,
    previousPositiveFactors: [String] = [],
    previousNegativeFactors: [String] = []
  ) {
    self.healthContext = healthContext
    self.chronologicalAge = chronologicalAge
    self.previousBiologicalAge = previousBiologicalAge
    self.previousPositiveFactors = previousPositiveFactors
    self.previousNegativeFactors = previousNegativeFactors
  }
}
