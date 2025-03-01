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
    case .targetHeartRateZone1Minutes: TargetMetric.targetHeartRateZone1
    case .targetHeartRateZone2Minutes: TargetMetric.targetHeartRateZone2
    case .targetHeartRateZone3Minutes: TargetMetric.targetHeartRateZone3
    case .targetHeartRateZone4Minutes: TargetMetric.targetHeartRateZone4
    case .targetHeartRateZone5Minutes: TargetMetric.targetHeartRateZone5
    }
  }
}
