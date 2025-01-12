//
//  ExerciseEffectivenessGoalFactory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-12.
//

import Foundation
import DataContainer

final class ExerciseEffectivenessGoalFactory: Sendable {
  let goalFactory = GoalFactory()
  let vitalKind: VitalModel.Kind = .exerciseEffectiveness
}

extension ExerciseEffectivenessGoalFactory {

  func createGoals() async -> [ProposedGoal] {
    [
      await goalFactory.createHabit(
        targetMetric: .exerciseMinutes,
        unit: .minute(),
        vitalKind: vitalKind,
        context: "Getting any type of exercise will help you get more zone minutes."
      ),
      await goalFactory.createHabit(
        targetMetric: .runDistance,
        unit: .meterUnit(with: .kilo),
        vitalKind: vitalKind,
        context: "Running is a great way to spend time in different target heart rate zones."
      ),
      await goalFactory.createHabit(
        targetMetric: .targetHeartRateZone1,
        unit: .minute(),
        vitalKind: vitalKind,
        context: "Zone 1 is the easiest way to get your zone minutes."
      ),
      await goalFactory.createHabit(
        targetMetric: .targetHeartRateZone2,
        unit: .minute(),
        vitalKind: vitalKind,
        context: "Zone 2 is a bit more intense than Zone 1, but still a good way to get your zone minutes."
      ),
      await goalFactory.createHabit(
        targetMetric: .targetHeartRateZone3,
        unit: .minute(),
        vitalKind: vitalKind,
        context: "Zone 3 is moderately intense, but every minute spent here is worth 2x the zone minutes."
      ),
      await goalFactory.createHabit(
        targetMetric: .targetHeartRateZone4,
        unit: .minute(),
        vitalKind: vitalKind,
        context: "Zone 4 is a bit more intense than Zone 3, but still gets 2x the zone minutes."
      ),
      await goalFactory.createHabit(
        targetMetric: .targetHeartRateZone5,
        unit: .minute(),
        vitalKind: vitalKind,
        context: "Zone 5 is the most intense zone, which is why every minute is worth 3x the zone minutes!"
      )
    ]
  }
}
