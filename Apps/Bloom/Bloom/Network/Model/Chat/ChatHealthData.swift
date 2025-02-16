//
//  ChatHealthData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import Foundation

// MARK: - ChatHealthData

public struct ChatHealthData: Codable, Equatable, Sendable {
  public let heartHealth: HeartHealth?

  public init(
    heartHealth: HeartHealth?
  ) {
    self.heartHealth = heartHealth
  }
}

// MARK: - Primitives

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

// MARK: - Heart Health

public extension ChatHealthData {
  struct HeartHealth: Codable, Equatable, Sendable {
    public let vo2Max: [Sample]
    public let restingHeartRate: [Sample]
    public let heartRateRecovery: [Sample]

    public init(
      vo2Max: [Sample],
      restingHeartRate: [Sample],
      heartRateRecovery: [Sample]
    ) {
      self.vo2Max = vo2Max
      self.restingHeartRate = restingHeartRate
      self.heartRateRecovery = heartRateRecovery
    }
  }
}
