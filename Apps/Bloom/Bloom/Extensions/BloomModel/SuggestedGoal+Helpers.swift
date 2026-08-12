//
//  SuggestedGoal+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-01.
//

import DataContainer
import BloomModel
import HealthKit

extension SuggestedGoal.Metric {

  var targetMetric: TargetMetric {
    switch self {
    case .calories: TargetMetric.calories
    case .proteinIntake: TargetMetric.proteinIntake
    case .stepCount: TargetMetric.stepCount
    case .waterIntake: TargetMetric.waterIntake
    case .fiberIntake: TargetMetric.fiberIntake
    case .meditationMinutes: TargetMetric.meditationMinutes
    case .exerciseMinutes: TargetMetric.exerciseMinutes
    case .workoutMinutes: TargetMetric.workoutMinutes
    case .walkingRunningDistance: TargetMetric.walkingRunningDistance
    case .runDistance: TargetMetric.runDistance
    case .runDuration: TargetMetric.runDuration
    case .bikeDistance: TargetMetric.bikeDistance
    case .bikeDuration: TargetMetric.bikeDuration
    case .mobilityAndFlexibilityDuration: TargetMetric.mobilityAndFlexibilityDuration
    case .strengthTrainingDuration: TargetMetric.strengthTrainingDuration
    case .cardioDuration: TargetMetric.cardioDuration
    case .highIntensityIntervalTrainingDuration: TargetMetric.highIntensityIntervalTrainingDuration
    case .targetHeartRateZone1Minutes: TargetMetric.targetHeartRateZone1
    case .targetHeartRateZone2Minutes: TargetMetric.targetHeartRateZone2
    case .targetHeartRateZone3Minutes: TargetMetric.targetHeartRateZone3
    case .targetHeartRateZone4Minutes: TargetMetric.targetHeartRateZone4
    case .targetHeartRateZone5Minutes: TargetMetric.targetHeartRateZone5
    }
  }

  var name: String {
    switch self {
    case .calories: String(localized: "caloric intake")
    case .proteinIntake: String(localized: "protein intake")
    case .waterIntake: String(localized: "water intake")
    case .fiberIntake: String(localized: "fiber intake")
    case .meditationMinutes: String(localized: "meditation minutes")
    case .exerciseMinutes: String(localized: "exercise minutes")
    case .workoutMinutes: String(localized: "workout minutes")
    case .stepCount: String(localized: "steps")
    case .walkingRunningDistance: String(localized: "walking-running distance")
    case .runDistance: String(localized: "running distance")
    case .runDuration: String(localized: "running duration")
    case .bikeDistance: String(localized: "biking distance")
    case .bikeDuration: String(localized: "biking duration")
    case .mobilityAndFlexibilityDuration: String(localized: "mobility and flexibility workouts")
    case .strengthTrainingDuration: String(localized: "strength training workouts")
    case .cardioDuration: String(localized: "cardio workouts")
    case .highIntensityIntervalTrainingDuration: String(localized: "HIIT workouts")
    case .targetHeartRateZone1Minutes: String(localized: "target heart rate zone 1 minutes")
    case .targetHeartRateZone2Minutes: String(localized: "target heart rate zone 2 minutes")
    case .targetHeartRateZone3Minutes: String(localized: "target heart rate zone 3 minutes")
    case .targetHeartRateZone4Minutes: String(localized: "target heart rate zone 4 minutes")
    case .targetHeartRateZone5Minutes: String(localized: "target heart rate zone 5 minutes")
    }
  }
}

extension TargetMetric {
  var metric: SuggestedGoal.Metric? {
    switch self {
    case .none:
      return nil
    case .calories:
      return .calories
    case .proteinIntake:
      return .proteinIntake
    case .waterIntake:
      return .waterIntake
    case .fiberIntake:
      return .fiberIntake
    case .timeInDaylight:
        return nil // TODO: We need to figure out how to handle the fact that not all watches measure this.
    case .meditationMinutes:
      return  .meditationMinutes
    case .exerciseMinutes:
      return .exerciseMinutes
    case .stepCount:
      return .stepCount
    case .walkingRunningDistance:
      return .walkingRunningDistance
    case .runDistance:
      return .runDistance
    case .runDuration:
      return .runDuration
    case .bikeDistance:
      return .bikeDistance
    case .bikeDuration:
      return .bikeDuration
    case .mobilityAndFlexibilityDuration:
      return .mobilityAndFlexibilityDuration
    case .strengthTrainingDuration:
      return .strengthTrainingDuration
    case .cardioDuration:
      return .cardioDuration
    case .highIntensityIntervalTrainingDuration:
      return .highIntensityIntervalTrainingDuration
    case .targetHeartRateZone1:
      return .targetHeartRateZone1Minutes
    case .targetHeartRateZone2:
      return .targetHeartRateZone2Minutes
    case .targetHeartRateZone3:
      return .targetHeartRateZone3Minutes
    case .targetHeartRateZone4:
      return .targetHeartRateZone4Minutes
    case .targetHeartRateZone5:
      return .targetHeartRateZone5Minutes
    case .workoutMinutes:
      return .workoutMinutes
    @unknown default:
      fatalError("Unknown Target Metric")
    }
  }
}

extension SuggestedGoal.Unit {

  var hkUnit: HKUnit {
    switch self {
    case .g:
        .gram()
    case .mg:
        .gramUnit(with: .milli)
    case .mcg:
        .gramUnit(with: .micro)
    case .steps:
        .count()
    case .mL:
        .literUnit(with: .milli)
    case .min:
        .minute()
    case .hr:
        .hour()
    case .oz:
        .fluidOunceUS()
    case .km:
        .meterUnit(with: .kilo)
    case .mi:
        .mile()
    case .cal:
        .largeCalorie()
    }
  }
}
