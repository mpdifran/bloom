//
//  SuggestedGoal+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-01.
//

import DataContainer
import BloomModel

extension SuggestedGoal.Metric {

  var targetMetric: TargetMetric {
    switch self {
    case .stepCount: TargetMetric.stepCount
    case .waterIntake: TargetMetric.waterIntake
    case .fiberIntake: TargetMetric.fiberIntake
    case .meditationMinutes: TargetMetric.meditationMinutes
    case .exerciseMinutes: TargetMetric.exerciseMinutes
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
}

extension TargetMetric {
  var metric: SuggestedGoal.Metric? {
    switch self {
    case .calories, .proteinIntake, .none:
      return nil
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
    @unknown default:
      fatalError("Unknown Target Metric")
    }
  }
}
