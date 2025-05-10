//
//  ProteinTargetCalculator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-01.
//

import Foundation
import HealthKit
import DataContainer
import CoreHealth

extension Double {
  static let targetProteinPercent: Double = 0.3
}

final class ProteinTargetCalculator {

  private let calorieGoal: HKQuantity
  private let targetDetails: HealthTargetDetails

  init(
    calorieGoal: HKQuantity,
    targetDetails: HealthTargetDetails
  ) {
    self.calorieGoal = calorieGoal
    self.targetDetails = targetDetails
  }
}

extension ProteinTargetCalculator {

  func targetProtein(existingHabit: HabitDTO?) async -> TargetMetricRecommendation {
    if let existingHabit {
      return await updateExistingHabit(existingHabit: existingHabit)
    }
    return createNewProteinGoal()
  }
}

private extension ProteinTargetCalculator {

  func createNewProteinGoal() -> TargetMetricRecommendation {
    let proteinTarget = calculateTargetProtein()

    let context: String = "It's important to make sure your protein intake remains balanced."
//    switch targetDetails.goal {
//    case .loseWeight:
//      context = "Eating more protein can help you stay satiated and lose weight sustainably."
//    case .gainWeight:
//      context = "Eating more protein can help you gain weight sustainably."
//    case .maintainWeight, .none:
//      context = "It's important to make sure your protein intake remains balanced."
//    }

    return TargetMetricRecommendation(
      target: proteinTarget,
      context: context
    )
  }

  func updateExistingHabit(existingHabit: HabitDTO) async -> TargetMetricRecommendation {
    let proteinTarget = calculateTargetProtein()
    let habitGoalStatistics = await HabitGoalStatisticsCalculator.calculateStatistics(for: existingHabit)

    let context: String
    if habitGoalStatistics.missedGoalCountPercentage > 0.4 {
      context = "Looks like you haven't been hitting your protein goal recently. Let's turn over a leaf this week!"
    } else if habitGoalStatistics.missedGoalSamples.count < 3 {
      context = "Great job getting your protein! Keep it up!"
    } else {
      context = "Great job on getting your protein! Keep it up!"
    }

    return TargetMetricRecommendation(
      target: proteinTarget,
      context: context
    )
  }

  func calculateTargetProtein() -> HKQuantity {
    let targetProteinCals = calorieGoal.doubleValue(for: .largeCalorie()) * .targetProteinPercent
    let targetProteinGrams = targetProteinCals / .caloriesPerGramOfProtein

    let minProteinTarget = TargetMetric.proteinIntake.minHabitTarget.doubleValue(for: .gram())
    let cappedProteinGrams = max(targetProteinGrams, minProteinTarget)

    return HKQuantity(unit: .gram(), doubleValue: cappedProteinGrams.roundedToNearest(divisor: 1))
  }
}
