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
    case .nutrition: String(localized: "nutrition")
    case .goals: String(localized: "goals")
    case .activityLevel: String(localized: "activity level")
    case .bodyWeight: String(localized: "body weight")
    case .bowelMovements: String(localized: "bowel movements")
    case .heart: String(localized: "heart health")
    case .menstruation: String(localized: "cycle tracking")
    case .sleep: String(localized: "sleep")
    case .stress: String(localized: "stress")
    case .workouts: String(localized: "workouts")
    case .targetHeartRateZoneMinutes: String(localized: "target heart rate zones")
    case .caloricIntake: String(localized: "caloric intake")
    case .proteinIntake: String(localized: "protein intake")
    case .waterIntake: String(localized: "water intake")
    case .fiberIntake: String(localized: "fiber intake")
    case .meditationMinutes: String(localized: "meditation minutes")
    case .exerciseMinutes: String(localized: "exercise minutes")
    case .stepCount: String(localized: "step count")
    case .walkingRunningDistance: String(localized: "walking running distance")
    case .runDistance: String(localized: "run distance")
    case .runDuration: String(localized: "run duration")
    case .bikeDistance: String(localized: "bike distance")
    case .bikeDuration: String(localized: "bike duration")
    case .mobilityAndFlexibilityDuration: String(localized: "mobility and flexibility duration")
    case .strengthTrainingDuration: String(localized: "strength training duration")
    case .cardioDuration: String(localized: "cardio duration")
    case .highIntensityIntervalTrainingDuration: String(localized: "high intensity interval training duration")
    case .reminders: String(localized: "reminders")
    }
  }
}
