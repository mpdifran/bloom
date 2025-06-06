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
    public let dataType: QueryDataType

    public init(
      startDate: Date,
      endDate: Date,
      dataType: QueryDataType
    ) {
      self.startDate = startDate
      self.endDate = endDate
      self.dataType = dataType
    }
  }
}

public extension SocketMessage {
  enum QueryDataType: String, Codable, Equatable, Sendable, CaseIterable {
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
    case caloricIntake
    case proteinIntake
    case waterIntake
    case fiberIntake
    case meditationMinutes
    case exerciseMinutes
    case stepCount
    case walkingRunningDistance
    case runDistance
    case runDuration
    case bikeDistance
    case bikeDuration
    case mobilityAndFlexibilityDuration
    case strengthTrainingDuration
    case cardioDuration
    case highIntensityIntervalTrainingDuration
    case reminders
    case userFacts
  }
}
