//
//  GoalFactory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-12.
//

import Foundation
import SwiftData
import DataContainer
import HealthKit

final class GoalFactory: Sendable {
  let modelActor = HabitModelActor.standard()
}

extension GoalFactory {

  func createHabit(
    targetMetric: TargetMetric,
    unit: HKUnit,
    vitalKind: VitalModel.Kind?,
    context: String?
  ) async -> ProposedGoal {
    let average = await targetMetric.fetchDailyAverage(unit: unit, dateRange: .trailingWeeksFromNow(3)).doubleValue(for: unit)

    let min = targetMetric.minHabitTarget.doubleValue(for: unit)

    var value = max(min, average)
    var suggestedValue = value
    var resolvedContext: String?

    let existingGoal = (try? await modelActor.fetchActiveHabits(for: targetMetric))?.first

    if let existingGoal {
      // Calculate what the recommendation should be.
      if let recommendation = await GenericHabitTargetCalculator.calculateNewTarget(habit: existingGoal) {
        suggestedValue = recommendation.target.doubleValue(for: existingGoal.unit)
        value = suggestedValue
        resolvedContext = recommendation.context
      }

      // If it's been user edited, don't change the value.
      if existingGoal.isUserEdited {
        value = existingGoal.value
      }
    }

    return ProposedGoal(
      habitID: existingGoal?.id,
      targetMetric: targetMetric,
      value: value,
      suggestedValue: suggestedValue,
      previousValue: existingGoal?.value,
      unitString: unit.unitString,
      vitalKind: vitalKind,
      context: resolvedContext ?? context,
      hasUserEdited: existingGoal?.isUserEdited ?? false
    )
  }
}
