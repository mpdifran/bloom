//
//  TargetMetric+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-24.
//

import SwiftUI
import DataContainer

public extension TargetMetric {

  var name: String {
    switch self {
    case .none: String(localized: "None", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .calories: String(localized: "Dietary Calories", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .proteinIntake: String(localized: "Protein Intake", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .waterIntake: String(localized: "Water Intake", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .fiberIntake: String(localized: "Fiber Intake", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .timeInDaylight: String(localized: "Time in Daylight", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .meditationMinutes: String(localized: "Meditation Minutes", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .exerciseMinutes: String(localized: "Apple Watch Exercise Minutes", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .workoutMinutes: String(localized: "Workout Duration", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .stepCount: String(localized: "Steps", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .walkingRunningDistance: String(localized: "Walking + Running Distance", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .runDistance: String(localized: "Running Distance", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .runDuration: String(localized: "Running Duration", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .bikeDistance: String(localized: "Bike Distance", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .bikeDuration: String(localized: "Bike Duration", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .mobilityAndFlexibilityDuration: String(localized: "Mobility & Flexibility", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .strengthTrainingDuration: String(localized: "Strength Training", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .cardioDuration: String(localized: "Cardio Workouts", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .highIntensityIntervalTrainingDuration: String(localized: "HIIT Workouts", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .targetHeartRateZone1: String(localized: "Target Heart Rate Zone 1", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .targetHeartRateZone2: String(localized: "Target Heart Rate Zone 2", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .targetHeartRateZone3: String(localized: "Target Heart Rate Zone 3", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .targetHeartRateZone4: String(localized: "Target Heart Rate Zone 4", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    case .targetHeartRateZone5: String(localized: "Target Heart Rate Zone 5", bundle: Bundle.coreHealth, comment: "Display name for target metric")
    @unknown default: String(localized: "Unknown", bundle: Bundle.coreHealth, comment: "Display name for target metric")
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
    case .exerciseMinutes: "applewatch.side.right"
    case .workoutMinutes: "figure.step.training"
    case .stepCount: "figure.walk"
    case .walkingRunningDistance: "figure.walk"
    case .runDistance, .runDuration: "figure.run"
    case .bikeDistance, .bikeDuration: "figure.outdoor.cycle"
    case .mobilityAndFlexibilityDuration: "figure.yoga"
    case .strengthTrainingDuration: "figure.strengthtraining.traditional"
    case .cardioDuration: "figure.mixed.cardio"
    case .highIntensityIntervalTrainingDuration: "figure.highintensity.intervaltraining"
    case .targetHeartRateZone1: "1.circle.fill"
    case .targetHeartRateZone2: "2.circle.fill"
    case .targetHeartRateZone3: "3.circle.fill"
    case .targetHeartRateZone4: "4.circle.fill"
    case .targetHeartRateZone5: "5.circle.fill"
    @unknown default: "xmark.app"
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
    case .exerciseMinutes, .workoutMinutes: .mutedGreen
    case .proteinIntake: .protein
    case .calories: .mutedOrange
    case .runDistance, .runDuration, .bikeDistance, .bikeDuration, .mobilityAndFlexibilityDuration, .strengthTrainingDuration, .cardioDuration, .highIntensityIntervalTrainingDuration: .mutedGreen
    case .targetHeartRateZone1: .heartRateZone1
    case .targetHeartRateZone2: .heartRateZone2
    case .targetHeartRateZone3: .heartRateZone3
    case .targetHeartRateZone4: .heartRateZone4
    case .targetHeartRateZone5: .heartRateZone5
    @unknown default: .gray
    }
  }

  var related: [TargetMetric] {
    switch self {
    case .exerciseMinutes, .workoutMinutes:
      [.exerciseMinutes, .workoutMinutes].filter({ $0 != self })
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
