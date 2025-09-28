//
//  BiologicalAgeRequest.swift
//  bloom-model
//
//  Created by Assistant on 2025-09-14.
//

import Foundation

public struct BiologicalAgeRequest: Codable, Hashable, Sendable {
  public let healthContext: String // JSON blob of health data

  public init(healthContext: String) {
    self.healthContext = healthContext
  }
}
