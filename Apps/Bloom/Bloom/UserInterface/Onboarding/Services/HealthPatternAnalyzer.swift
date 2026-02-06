//
//  HealthPatternAnalyzer.swift
//  Bloom
//
//  Created by Claude on 2025-09-03.
//

import Foundation
import HealthKit
import CoreHealth
import DataContainer
import BloomFoundation

struct UserHealthPattern: Sendable {
  let averageStepsPerDay: Double
  let averageExerciseMinutesPerWeek: Double
  let primaryWorkoutTypes: [HKWorkoutActivityType]
  let workoutFrequencyByType: [HKWorkoutActivityType: WorkoutFrequency]
  let preferredWorkoutDays: [Int]
  let hasRegularMeditationPractice: Bool
  let averageMeditationMinutesPerWeek: Double
  let activityLevel: ActivityLevelSummary.ActivityLevel?
}

struct WorkoutFrequency: Sendable {
  let totalInstances: Int
  let averageInstancesPerWeek: Double
  let totalMinutesPerWeek: Double
  let preferredDays: [Int]
  let isRegular: Bool
  
  var shouldSuggestDaily: Bool {
    averageInstancesPerWeek >= 4.0
  }
  
  var shouldSuggestWeekly: Bool {
    averageInstancesPerWeek >= 1.0 && averageInstancesPerWeek < 4.0
  }
}

final actor HealthPatternAnalyzer {
  static let shared = HealthPatternAnalyzer()
  
  private init() {}
  
  func analyzeUserHealthPattern() async -> UserHealthPattern {
    let analysisDateRange = DateRange.trailingMonthsFromNow(1)
    
    async let stepData = analyzeStepPattern(dateRange: analysisDateRange)
    async let workoutData = analyzeWorkoutPatterns(dateRange: analysisDateRange)
    async let meditationData = analyzeMeditationPattern(dateRange: analysisDateRange)
    async let activityLevel = getActivityLevel()
    
    let (averageSteps, workouts, meditation, level) = await (stepData, workoutData, meditationData, activityLevel)

    return UserHealthPattern(
      averageStepsPerDay: averageSteps,
      averageExerciseMinutesPerWeek: workouts.totalMinutesPerWeek,
      primaryWorkoutTypes: workouts.primaryTypes,
      workoutFrequencyByType: workouts.frequencyByType,
      preferredWorkoutDays: workouts.preferredDays,
      hasRegularMeditationPractice: meditation.isRegular,
      averageMeditationMinutesPerWeek: meditation.averageMinutesPerWeek,
      activityLevel: level
    )
  }
}

private extension HealthPatternAnalyzer {
  
  func analyzeStepPattern(dateRange: DateRange) async -> Double {
    let stepData = await HealthStoreFetcher.shared.fetchCollatedQuantity(
      for: .stepCount,
      unit: .count(),
      dateRange: dateRange
    )
    
    let nonZeroSteps = stepData.filter { $0.quantity.doubleValue(for: .count()) > 100 }
    let averageSteps = nonZeroSteps.map { $0.quantity.doubleValue(for: .count()) }.average(keyPath: \.self)
    
    return averageSteps
  }
  
  func analyzeWorkoutPatterns(dateRange: DateRange) async -> (
    totalMinutesPerWeek: Double,
    primaryTypes: [HKWorkoutActivityType],
    frequencyByType: [HKWorkoutActivityType: WorkoutFrequency],
    preferredDays: [Int]
  ) {
    let workoutSummations = await HealthStoreFetcher.shared.fetchWorkoutSummations(dateRange: dateRange)
    let collatedWorkouts = await HealthStoreFetcher.shared.fetchCollatedWorkouts(dateRange: dateRange)
    
    let totalWorkouts = collatedWorkouts.flatMap { $0.workouts }
    let totalMinutes = totalWorkouts.reduce(0) { $0 + $1.duration }
    let totalMinutesPerWeek = (totalMinutes / 60.0) * (7.0 / Double(dateRange.numberOfDaysInclusive))
    
    var frequencyByType = [HKWorkoutActivityType: WorkoutFrequency]()
    let weeksInRange = Double(dateRange.numberOfDaysInclusive) / 7.0
    
    for summation in workoutSummations {
      let workoutsOfType = totalWorkouts.filter { $0.workoutActivityType == summation.activityType }
      let daysWithWorkouts = Set(workoutsOfType.map { Calendar.current.component(.weekday, from: $0.startDate) })
      let totalMinutesOfType = workoutsOfType.reduce(0) { $0 + ($1.duration / 60.0) }
      let totalMinutesPerWeek = totalMinutesOfType * (7.0 / Double(dateRange.numberOfDaysInclusive))
      
      let frequency = WorkoutFrequency(
        totalInstances: summation.instances,
        averageInstancesPerWeek: Double(summation.instances) / weeksInRange,
        totalMinutesPerWeek: totalMinutesPerWeek,
        preferredDays: Array(daysWithWorkouts).sorted(),
        isRegular: Double(summation.instances) / weeksInRange >= 1.0
      )
      frequencyByType[summation.activityType] = frequency
    }
    
    let primaryTypes = workoutSummations.prefix(3).map { $0.activityType }
    
    let allWorkoutDays = totalWorkouts.map { Calendar.current.component(.weekday, from: $0.startDate) }
    let dayFrequency = Dictionary(grouping: allWorkoutDays, by: { $0 })
      .mapValues { $0.count }
      .sorted { $0.value > $1.value }
      .prefix(3)
      .map { $0.key }
    
    return (
      totalMinutesPerWeek: totalMinutesPerWeek,
      primaryTypes: Array(primaryTypes),
      frequencyByType: frequencyByType,
      preferredDays: Array(dayFrequency)
    )
  }
  
  func analyzeMeditationPattern(dateRange: DateRange) async -> (isRegular: Bool, averageMinutesPerWeek: Double) {
    let totalMeditationMinutes = await HealthStoreFetcher.shared.fetchTotalMeditationMinutes(dateRange: dateRange)
    let totalMinutes = totalMeditationMinutes.doubleValue(for: .minute())
    let averageMinutesPerWeek = totalMinutes * (7.0 / Double(dateRange.numberOfDaysInclusive))
    
    let collatedMeditation = await HealthStoreFetcher.shared.fetchCollatedMeditationMinutes(dateRange: dateRange)
    let daysWithMeditation = collatedMeditation.count { $0.quantity.doubleValue(for: .minute()) > 0 }
    let meditationFrequency = Double(daysWithMeditation) / Double(dateRange.numberOfDaysInclusive)
    
    return (
      isRegular: meditationFrequency >= 0.3 && averageMinutesPerWeek >= 30,
      averageMinutesPerWeek: averageMinutesPerWeek
    )
  }
  
  func getActivityLevel() async -> ActivityLevelSummary.ActivityLevel? {
    return await YouStatsCalculator.shared.activityLevelSummary?.details.activityLevel
  }
}
