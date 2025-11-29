//
//  QueryDataTypeMapper.swift
//  Bloom
//
//  Created by Claude on 2025-11-29.
//

import BloomModel
import BloomUI

enum QueryDataTypeMapper {
  /// Maps a QueryDataType to its corresponding AIHealthCategory
  static func category(for dataType: SocketMessage.QueryDataType) -> AIHealthCategory? {
    switch dataType {
    // Physical Activity
    case .workouts, .activityLevel, .stepCount, .exerciseMinutes,
         .walkingRunningDistance, .runDistance, .runDuration,
         .bikeDistance, .bikeDuration, .mobilityAndFlexibilityDuration,
         .strengthTrainingDuration, .cardioDuration,
         .highIntensityIntervalTrainingDuration:
      return .physicalActivity

    // Body Metrics
    case .bodyWeight, .heart, .targetHeartRateZoneMinutes:
      return .bodyMetrics

    // Sleep
    case .sleep:
      return .sleep

    // Nutrition
    case .nutrition, .caloricIntake, .proteinIntake, .waterIntake, .fiberIntake:
      return .nutrition

    // Digestive Health
    case .bowelMovements:
      return .digestiveHealth

    // Mental Wellness
    case .stress, .meditationMinutes:
      return .mentalWellness

    // Menstrual Health
    case .menstruation:
      return .menstrualHealth

    // Goals
    case .goals, .reminders:
      return .goals
    }
  }

  /// Returns a simple error message for restricted data
  static func restrictionMessage(for category: AIHealthCategory) -> String {
    "This health data category (\(category.displayName)) is restricted by privacy settings."
  }
}
