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
    case .nutrition: "nutrition"
    case .goals: "goals"
    case .activityLevel: "activity level"
    case .bodyWeight: "body weight"
    case .bowelMovements: "bowel movements"
    case .heart: "heart health"
    case .menstruation: "cycle tracking"
    case .sleep: "sleep"
    case .stress: "stress"
    case .workouts: "workouts"
    case .targetHeartRateZoneMinutes: "target heart rate zones"
    case .caloricIntake: "caloric intake"
    case .proteinIntake: "protein intake"
    case .waterIntake: "water intake"
    case .fiberIntake: "fiber intake"
    case .meditationMinutes: "meditation minutes"
    case .exerciseMinutes: "exercise minutes"
    case .stepCount: "step count"
    case .walkingRunningDistance: "walking running distance"
    case .runDistance: "run distance"
    case .runDuration: "run duration"
    case .bikeDistance: "bike distance"
    case .bikeDuration: "bike duration"
    case .mobilityAndFlexibilityDuration: "mobility and flexibility duration"
    case .strengthTrainingDuration: "strength training duration"
    case .cardioDuration: "cardio duration"
    case .highIntensityIntervalTrainingDuration: "high intensity interval training duration"
    case .reminders: "reminders"
    }
  }
}
