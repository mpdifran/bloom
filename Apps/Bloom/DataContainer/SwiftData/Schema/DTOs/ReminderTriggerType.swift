//
//  ReminderTriggerType.swift
//  DataContainer
//
//  Created by Assistant on 2025-08-09.
//

import Foundation

/// Defines the types of automatic triggers that can complete a reminder
public enum ReminderTriggerType: String, Codable, CaseIterable, Sendable {
  case logWeight = "log_weight"
  case logWater = "log_water"
  case logBloodPressure = "log_blood_pressure"
  case logStrengthTraining = "log_strength_training"
  case logCardio = "log_cardio"
  case logMobilityFlexibility = "log_mobility_flexibility"
  case logHIIT = "log_hiit"
  
  public var displayName: String {
    switch self {
    case .logWeight:
      return "Log Weight"
    case .logWater:
      return "Log Water"
    case .logBloodPressure:
      return "Log Blood Pressure"
    case .logStrengthTraining:
      return "Log Strength Training"
    case .logCardio:
      return "Log Cardio Workout"
    case .logMobilityFlexibility:
      return "Log Mobility/Flexibility"
    case .logHIIT:
      return "Log HIIT Workout"
    }
  }
  
  public var description: String {
    switch self {
    case .logWeight:
      return "Automatically complete the reminder when you log your body weight."
    case .logWater:
      return "Automatically complete the reminder when you log water intake."
    case .logBloodPressure:
      return "Automatically complete the reminder when you log blood pressure."
    case .logStrengthTraining:
      return "Automatically complete the reminder when you log a strength training workout."
    case .logCardio:
      return "Automatically complete the reminder when you log a cardio workout."
    case .logMobilityFlexibility:
      return "Automatically complete the reminder when you log yoga, pilates, or flexibility."
    case .logHIIT:
      return "Automatically complete the reminder when you log a HIIT workout."
    }
  }
  
  public var systemImageName: String {
    switch self {
    case .logWeight:
      return "gauge.with.dots.needle.bottom.0percent"
    case .logWater:
      return "drop.fill"
    case .logBloodPressure:
      return "heart.text.square"
    case .logStrengthTraining:
      return "figure.strengthtraining.traditional"
    case .logCardio:
      return "figure.run"
    case .logMobilityFlexibility:
      return "figure.yoga"
    case .logHIIT:
      return "figure.highintensity.intervaltraining"
    }
  }
}
