//
//  ChatReportHealthDataRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-16.
//

import Foundation

public struct ChatReportHealthDataRequest: Codable, Equatable, Sendable {
  public let healthData: String

  public init(
    healthData: String
  ) {
    self.healthData = healthData
  }
}
