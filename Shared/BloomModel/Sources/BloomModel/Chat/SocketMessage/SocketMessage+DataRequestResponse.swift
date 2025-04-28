//
//  SocketMessage+DataRequestResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-02.
//

import Foundation

public extension SocketMessage {
  struct Query: Codable, Equatable, Sendable {
    public let startDate: Date
    public let endDate: Date
    public let dataType: QueryDataType?
    public let healthMetric: SuggestedGoal.Metric?

    public init(
      startDate: Date,
      endDate: Date,
      dataType: QueryDataType?,
      healthMetric: SuggestedGoal.Metric?
    ) {
      self.startDate = startDate
      self.endDate = endDate
      self.dataType = dataType
      self.healthMetric = healthMetric
    }
  }
}

public extension SocketMessage {
  enum QueryDataType: String, Codable, Equatable, Sendable, CaseIterable {
    case foodLogs
    case nutrition
    case goals
    case activityLevel
    case bodyWeight
    case bowelMovements
    case heart
    case menstruation
    case sleep
    case stress
    case workouts
    case targetHeartRateZoneMinutes
  }
}
