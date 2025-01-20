//
//  CalorieTargetCalculator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-01.
//

import Foundation
import HealthKit
import DataContainer

final class CalorieTargetCalculator {
  private let age: Int
  private let sex: HKBiologicalSex
  private let bodyMass: HKQuantity
  private let height: HKQuantity
  private let activityLevel: ActivityLevelSummary.ActivityLevel
  private let targetDetails: HealthTargetDetails

  init(
    age: Int,
    sex: HKBiologicalSex,
    bodyMass: HKQuantity,
    height: HKQuantity,
    activityLevel: ActivityLevelSummary.ActivityLevel,
    targetDetails: HealthTargetDetails
  ) {
    self.age = age
    self.sex = sex
    self.bodyMass = bodyMass
    self.height = height
    self.activityLevel = activityLevel
    self.targetDetails = targetDetails
  }
}

extension CalorieTargetCalculator {

  func targetCalories(existingHabit: HabitDTO?) async -> TargetMetricRecommendation? {
    if let existingHabit {
      return await updateExistingHabit(existingHabit: existingHabit)
    } else {
      return createNewCalorieGoal()
    }
  }
}

private extension CalorieTargetCalculator {

  func createNewCalorieGoal() -> TargetMetricRecommendation? {
    calculateMifflinStJeorCalorieGoal()
  }
}

private extension CalorieTargetCalculator {

  func calculateMifflinStJeorCalorieGoal() -> TargetMetricRecommendation? {
    let bmr: Double
    switch sex {
    case .female, .notSet:
      bmr = 10 * bodyMass.doubleValue(for: .gramUnit(with: .kilo))
        + 6.25 * height.doubleValue(for: .meterUnit(with: .centi))
        - 5 * Double(age)
        - 161
    case .male:
      bmr = 10 * bodyMass.doubleValue(for: .gramUnit(with: .kilo))
        + 6.25 * height.doubleValue(for: .meterUnit(with: .centi))
        - 5 * Double(age)
        + 5
    default:
      return nil
    }

    let tdeeEstimate = bmr * activityLevel.mifflinStJeorMultiplier
    let shift: Double
    let context: String
    switch targetDetails.goal {
    case .loseWeight:
      shift = -targetDetails.weightLossSpeed.mifflinStJeorAdjustment
      context = "Maintaining a calorie deficit is an important part of losing weight."
    case .maintainWeight:
      shift = 0
      context = "Try and maintain the same calorie intake to maintain your current weight."
    case .gainWeight:
      shift = targetDetails.weightLossSpeed.mifflinStJeorAdjustment
      context = "Maintaining a calorie surplus is an important part of gaining weight."
    case .none:
      return nil
    }

    let targetCalories = tdeeEstimate + shift
    let minCalorieTarget = TargetMetric.calories.minHabitTarget.doubleValue(for: .largeCalorie())
    let cappedTargetCalories = max(targetCalories, minCalorieTarget) // Ensure we never go too low

    return TargetMetricRecommendation(
      target: HKQuantity(unit: .largeCalorie(), doubleValue: cappedTargetCalories.roundedToNearest(divisor: 25)),
      context: context
    )
  }
}

private extension CalorieTargetCalculator {

  func updateExistingHabit(existingHabit: HabitDTO) async -> TargetMetricRecommendation? {

    if
      let recommendation = calculateMifflinStJeorCalorieGoal(),
      !recommendation.target.doubleValue(for: .largeCalorie()).isWithinRange(of: existingHabit.value, precision: 0.1)
    {
      return TargetMetricRecommendation(
        target: recommendation.target,
        context: "This new calorie target should help you meet your overall health goals."
      )
    }

    // If we're not changing it because of the above, then keep the goal the same.

    let habitGoalStatistics = await HabitGoalStatisticsCalculator.calculateStatistics(for: existingHabit)

    let context: String
    if habitGoalStatistics.missedGoalCountPercentage > 0.4 {
      context = "Looks like you had some trouble hitting this goal last week. Let's turn over a new leaf this week!"
    } else if habitGoalStatistics.missedGoalSamples.count < 3 {
      context = "Great job hitting this goal over the last couple weeks, keep up the good work!"
    } else {
      context = "You're on the right track, keep it up!"
    }

    return TargetMetricRecommendation(
      target: existingHabit.quantity,
      context: context
    )
  }
}
