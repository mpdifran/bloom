//
//  SocketMessageChatMessages+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-16.
//

import BloomModel

extension SocketMessage.RichMessageResponse.Kind {
  var telemetryName: String {
    switch self {
    case .newGoals:
      "New Goals"
    case .detectedFood:
      "Detected Food"
    case .logWeight:
      "Log Weight"
    case .logPeriod:
      "Log Period"
    case .logWater:
      "Log Water"
    case .logBloodPressure:
      "Log Blood Pressure"
    case .logBowelMovement:
      "Log Bowel Movement"
    case .createWorkout:
      "Create Workout"
    case .createReminder:
      "Create Reminder"
    case .deleteReminder:
      "Delete Reminder"
    case .createUserFacts:
      "Create User Fact"
    case .deleteUserFacts:
      "Delete User Fact"
    case .invalid:
      "Invalid"
    }
  }
}
