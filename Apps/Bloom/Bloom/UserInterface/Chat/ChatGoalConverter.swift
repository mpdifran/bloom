//
//  ChatGoalConverter.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-21.
//

import Foundation
import DataContainer
import BloomModel

final actor ChatGoalConverter {
  static let shared = ChatGoalConverter()

  private let modelActor = HabitModelActor.standard()

  private init() { }
}

extension ChatGoalConverter {

  func convertGoalData() async -> CurrentGoalsData? {
    do {
      let activeGoals = try await modelActor.fetchActiveHabits()

      let excludedTargetMetrics = [
        TargetMetric.calories,
        TargetMetric.proteinIntake
      ]
      let goals = activeGoals
        .filter {
          !excludedTargetMetrics.contains($0.targetMetric)
        }
        .compactMap { targetMetric -> GoalSummary? in
          guard let metric = targetMetric.targetMetric.metric else { return nil }

          return GoalSummary(
            metric: metric,
            value: targetMetric.value,
            unit: targetMetric.unit.sensibleUnitString
          )
        }

      return CurrentGoalsData(currentGoals: goals)
    } catch {
      print(error)
    }
    return nil
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
      return nil
    }
  }
}
