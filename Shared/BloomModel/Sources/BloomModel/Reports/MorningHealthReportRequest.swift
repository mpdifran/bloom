//
//  MorningHealthReportRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-07-23.
//

import Foundation

public struct MorningHealthReportRequest: Codable, Hashable, Sendable {
  public let healthContext: String

  public init(healthContext: String) {
    self.healthContext = healthContext
  }
}
