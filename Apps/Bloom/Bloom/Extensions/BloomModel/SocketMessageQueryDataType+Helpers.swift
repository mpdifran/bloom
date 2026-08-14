//
//  SocketMessageQueryDataType+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-14.
//

import BloomModel

extension SocketMessage.QueryDataType {

  var name: String {
    switch self {
    case .nutrition: String(localized: "nutrition", comment: "Display name for query data type")
    case .goals: String(localized: "goals", comment: "Display name for query data type")
    case .activityLevel: String(localized: "activity level", comment: "Display name for query data type")
    case .bodyWeight: String(localized: "body weight", comment: "Display name for query data type")
    case .bowelMovements: String(localized: "bowel movements", comment: "Display name for query data type")
    case .heart: String(localized: "heart health", comment: "Display name for query data type")
    case .menstruation: String(localized: "cycle tracking", comment: "Display name for query data type")
    case .sleep: String(localized: "sleep", comment: "Display name for query data type")
    case .stress: String(localized: "stress", comment: "Display name for query data type")
    case .workouts: String(localized: "workouts", comment: "Display name for query data type")
    case .targetHeartRateZoneMinutes: String(localized: "target heart rate zones", comment: "Display name for query data type")
    case .caloricIntake: String(localized: "caloric intake", comment: "Display name for query data type")
    case .proteinIntake: String(localized: "protein intake", comment: "Display name for query data type")
    case .waterIntake: String(localized: "water intake", comment: "Display name for query data type")
    case .fiberIntake: String(localized: "fiber intake", comment: "Display name for query data type")
    case .meditationMinutes: String(localized: "meditation minutes", comment: "Display name for query data type")
    case .exerciseMinutes: String(localized: "exercise minutes", comment: "Display name for query data type")
    case .stepCount: String(localized: "step count", comment: "Display name for query data type")
    case .walkingRunningDistance: String(localized: "walking running distance", comment: "Display name for query data type")
    case .runDistance: String(localized: "run distance", comment: "Display name for query data type")
    case .runDuration: String(localized: "run duration", comment: "Display name for query data type")
    case .bikeDistance: String(localized: "bike distance", comment: "Display name for query data type")
    case .bikeDuration: String(localized: "bike duration", comment: "Display name for query data type")
    case .mobilityAndFlexibilityDuration: String(localized: "mobility and flexibility duration", comment: "Display name for query data type")
    case .strengthTrainingDuration: String(localized: "strength training duration", comment: "Display name for query data type")
    case .cardioDuration: String(localized: "cardio duration", comment: "Display name for query data type")
    case .highIntensityIntervalTrainingDuration: String(localized: "high intensity interval training duration", comment: "Display name for query data type")
    case .reminders: String(localized: "reminders", comment: "Display name for query data type")
    }
  }
}
