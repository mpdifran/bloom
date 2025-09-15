//
//  BiologicalAgeResponse.swift
//  bloom-model
//
//  Created by Assistant on 2025-09-14.
//

import Foundation

public struct BiologicalAgeResponse: Codable, Hashable, Sendable {
  public let biologicalAge: Double // Calculated biological age
  public let summary: String // Explanation of why the age is what it is
  public let positiveFactors: [String] // Factors that positively influence biological age
  public let negativeFactors: [String] // Factors that negatively influence biological age
  
  public init(
    biologicalAge: Double,
    summary: String,
    positiveFactors: [String],
    negativeFactors: [String]
  ) {
    self.biologicalAge = biologicalAge
    self.summary = summary
    self.positiveFactors = positiveFactors
    self.negativeFactors = negativeFactors
  }
}