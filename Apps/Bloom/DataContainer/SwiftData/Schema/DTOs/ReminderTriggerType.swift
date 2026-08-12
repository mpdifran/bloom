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
      return String(localized: "Log Weight", bundle: Bundle.dataContainer)
    case .logWater:
      return String(localized: "Log Water", bundle: Bundle.dataContainer)
    case .logBloodPressure:
      return String(localized: "Log Blood Pressure", bundle: Bundle.dataContainer)
    case .logStrengthTraining:
      return String(localized: "Log Strength Training", bundle: Bundle.dataContainer)
    case .logCardio:
      return String(localized: "Log Cardio Workout", bundle: Bundle.dataContainer)
    case .logMobilityFlexibility:
      return String(localized: "Log Mobility/Flexibility", bundle: Bundle.dataContainer)
    case .logHIIT:
      return String(localized: "Log HIIT Workout", bundle: Bundle.dataContainer)
    }
  }
  
  public var description: String {
    switch self {
    case .logWeight:
      return String(localized: "Automatically complete the reminder when you log your body weight.", bundle: Bundle.dataContainer)
    case .logWater:
      return String(localized: "Automatically complete the reminder when you log water intake.", bundle: Bundle.dataContainer)
    case .logBloodPressure:
      return String(localized: "Automatically complete the reminder when you log blood pressure.", bundle: Bundle.dataContainer)
    case .logStrengthTraining:
      return String(localized: "Automatically complete the reminder when you log a strength training workout.", bundle: Bundle.dataContainer)
    case .logCardio:
      return String(localized: "Automatically complete the reminder when you log a cardio workout.", bundle: Bundle.dataContainer)
    case .logMobilityFlexibility:
      return String(localized: "Automatically complete the reminder when you log yoga, pilates, or flexibility.", bundle: Bundle.dataContainer)
    case .logHIIT:
      return String(localized: "Automatically complete the reminder when you log a HIIT workout.", bundle: Bundle.dataContainer)
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
