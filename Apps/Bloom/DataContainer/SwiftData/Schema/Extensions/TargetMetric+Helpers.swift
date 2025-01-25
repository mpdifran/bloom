//
//  TargetMetric+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-24.
//

import SwiftUI

public extension TargetMetric {

  var name: String {
    switch self {
    case .none: "None"
    case .calories: "Dietary Calories"
    case .proteinIntake: "Protein Intake"
    case .waterIntake: "Water Intake"
    case .fiberIntake: "Fiber Intake"
    case .timeInDaylight: "Time in Daylight"
    case .meditationMinutes: "Meditation Minutes"
    case .exerciseMinutes: "Exercise Minutes"
    case .stepCount: "Steps"
    case .walkingRunningDistance: "Walking + Running Distance"
    case .runDistance: "Running Distance"
    case .runDuration: "Running Duration"
    case .bikeDistance: "Bike Distance"
    case .bikeDuration: "Bike Duration"
    case .targetHeartRateZone1: "Target Heart Rate Zone 1"
    case .targetHeartRateZone2: "Target Heart Rate Zone 2"
    case .targetHeartRateZone3: "Target Heart Rate Zone 3"
    case .targetHeartRateZone4: "Target Heart Rate Zone 4"
    case .targetHeartRateZone5: "Target Heart Rate Zone 5"
    }
  }

  var systemImage: String {
    switch self {
    case .none: "xmark.app"
    case .calories: "carrot.fill"
    case .proteinIntake: "fork.knife"
    case .waterIntake: "waterbottle"
    case .fiberIntake: "leaf.fill"
    case .timeInDaylight: "sun.max.fill"
    case .meditationMinutes: "figure.mind.and.body"
    case .exerciseMinutes: "figure.step.training"
    case .stepCount: "figure.walk"
    case .walkingRunningDistance: "figure.walk"
    case .runDistance, .runDuration: "figure.run"
    case .bikeDistance, .bikeDuration: "figure.outdoor.cycle"
    case .targetHeartRateZone1: "1.circle.fill"
    case .targetHeartRateZone2: "2.circle.fill"
    case .targetHeartRateZone3: "3.circle.fill"
    case .targetHeartRateZone4: "4.circle.fill"
    case .targetHeartRateZone5: "5.circle.fill"
    }
  }

  var color: Color {
    switch self {
    case .none: .gray
    case .stepCount: .mutedGreen
    case .waterIntake: .mutedBlue
    case .fiberIntake: .fiber
    case .walkingRunningDistance: .mutedGreen
    case .timeInDaylight: .mutedOrange
    case .meditationMinutes: .mutedLightBlue
    case .exerciseMinutes: .mutedGreen
    case .proteinIntake: .protein
    case .calories: .mutedOrange
    case .runDistance, .runDuration, .bikeDistance, .bikeDuration: .mutedGreen
    case .targetHeartRateZone1: .heartRateZone1
    case .targetHeartRateZone2: .heartRateZone2
    case .targetHeartRateZone3: .heartRateZone3
    case .targetHeartRateZone4: .heartRateZone4
    case .targetHeartRateZone5: .heartRateZone5
    }
  }

  var measurementStyle: TargetMetric.MeasurementStyle {
    switch self {
    case .calories: .range
    default: .minimum
    }
  }

  var related: [TargetMetric] {
    switch self {
    case .stepCount, .walkingRunningDistance:
      [.stepCount, .walkingRunningDistance].filter({ $0 != self })
    case .runDistance, .runDuration:
      [.runDistance, .runDuration].filter({ $0 != self })
    case .bikeDistance, .bikeDuration:
      [.bikeDistance, .bikeDuration].filter({ $0 != self })
    case .targetHeartRateZone1, .targetHeartRateZone2, .targetHeartRateZone3, .targetHeartRateZone4, .targetHeartRateZone5:
      [.targetHeartRateZone1, .targetHeartRateZone2, .targetHeartRateZone3, .targetHeartRateZone4, .targetHeartRateZone5].filter({ $0 != self })
    default:
      []
    }
  }

  static func userSelectableMetrics(excluding: [TargetMetric]) -> [TargetMetric] {
    TargetMetric.allCases.filter { targetMetric in
      if targetMetric == .none { return false }

      return !excluding.contains(targetMetric)
    }
  }
}
