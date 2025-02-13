//
//  ChatHealthData.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-12.
//

import Foundation

public struct ChatHealthData: Codable, Equatable, Sendable {
  public let restingHeartRate: [Sample]
  public let heartRateVariability: [Sample]

  public init(
    restingHeartRate: [Sample],
    heartRateVariability: [Sample]
  ) {
    self.restingHeartRate = restingHeartRate
    self.heartRateVariability = heartRateVariability
  }
}

public extension ChatHealthData {
  struct Sample: Codable, Equatable, Sendable {
    public let date: Date
    public let value: Double
    public let unit: String

    public init(
      date: Date,
      value: Double,
      unit: String
    ) {
      self.date = date
      self.value = value
      self.unit = unit
    }
  }
}
