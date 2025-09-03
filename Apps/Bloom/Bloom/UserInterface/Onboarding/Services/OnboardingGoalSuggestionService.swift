//
//  OnboardingGoalSuggestionService.swift
//  Bloom
//
//  Created by Claude on 2025-09-03.
//

import Foundation
import HealthKit
import CoreHealth
import DataContainer
import BloomFoundation
import BloomModel

final actor OnboardingGoalSuggestionService {
  static let shared = OnboardingGoalSuggestionService()
  
  private let patternAnalyzer = HealthPatternAnalyzer.shared
  
  private init() {}
  
  func suggestGoalsForOnboarding() async -> [SuggestedGoal] {
    let healthPattern = await patternAnalyzer.analyzeUserHealthPattern()
    var suggestions = [SuggestedGoal]()
    
    suggestions.append(contentsOf: await suggestExerciseGoals(from: healthPattern))
    suggestions.append(contentsOf: await suggestActivityGoals(from: healthPattern))
    suggestions.append(contentsOf: await suggestWellnessGoals(from: healthPattern))
    
    if suggestions.count < 2 {
      suggestions.append(contentsOf: getDefaultOnboardingGoals())
    }
    
    return Array(suggestions.prefix(2))
  }
}

private extension OnboardingGoalSuggestionService {
  
  func suggestExerciseGoals(from pattern: UserHealthPattern) async -> [SuggestedGoal] {
    var goals = [SuggestedGoal]()
    
    for workoutType in pattern.primaryWorkoutTypes {
      guard let frequency = pattern.workoutFrequencyByType[workoutType],
            frequency.isRegular else { continue }
      
      if let goal = await createWorkoutGoal(for: workoutType, frequency: frequency) {
        goals.append(goal)
      }
    }
    
    return goals
  }
  
  func createWorkoutGoal(for workoutType: HKWorkoutActivityType, frequency: WorkoutFrequency) async -> SuggestedGoal? {
    let strengthTrainingTypes = [HKWorkoutActivityType].strengthTrainingTypes
    let cardioTypes = [HKWorkoutActivityType].cardioTypes
    let mobilityTypes = [HKWorkoutActivityType].mobilityAndFlexibilityTypes
    let hiitTypes = [HKWorkoutActivityType].highIntensityIntervalTrainingTypes
    
    switch workoutType {
    case let type where strengthTrainingTypes.contains(type):
      let timePeriod: SuggestedGoal.TimePeriod = frequency.shouldSuggestDaily ? .daily : .weekly
      let targetMinutes = frequency.shouldSuggestDaily ? 45.0 : (frequency.averageInstancesPerWeek * 50.0)
      
      return SuggestedGoal(
        metric: .strengthTrainingDuration,
        timePeriod: timePeriod,
        value: targetMinutes.roundedToNiceNumber(),
        unit: .min,
        notes: timePeriod == .daily ? 
          "Based on your regular strength training, aim for daily sessions" :
          "Based on your \(Int(frequency.averageInstancesPerWeek))x/week pattern, continue your strength routine"
      )
      
    case .running:
      let timePeriod: SuggestedGoal.TimePeriod = frequency.shouldSuggestDaily ? .daily : .weekly
      let targetMinutes = frequency.shouldSuggestDaily ? 30.0 : (frequency.averageInstancesPerWeek * 35.0)
      
      return SuggestedGoal(
        metric: .runDuration,
        timePeriod: timePeriod,
        value: targetMinutes.roundedToNiceNumber(),
        unit: .min,
        notes: "Continue your running routine with \(timePeriod.rawValue) goals"
      )
      
    case .cycling:
      let timePeriod: SuggestedGoal.TimePeriod = frequency.shouldSuggestDaily ? .daily : .weekly
      let targetMinutes = frequency.shouldSuggestDaily ? 45.0 : (frequency.averageInstancesPerWeek * 60.0)
      
      return SuggestedGoal(
        metric: .bikeDuration,
        timePeriod: timePeriod,
        value: targetMinutes.roundedToNiceNumber(),
        unit: .min,
        notes: "Keep up your cycling routine"
      )
      
    case let type where mobilityTypes.contains(type):
      let timePeriod: SuggestedGoal.TimePeriod = frequency.shouldSuggestDaily ? .daily : .weekly
      let targetMinutes = frequency.shouldSuggestDaily ? 20.0 : (frequency.averageInstancesPerWeek * 25.0)
      
      return SuggestedGoal(
        metric: .mobilityAndFlexibilityDuration,
        timePeriod: timePeriod,
        value: targetMinutes.roundedToNiceNumber(),
        unit: .min,
        notes: "Build on your mobility and flexibility practice"
      )
      
    case let type where hiitTypes.contains(type):
      let timePeriod: SuggestedGoal.TimePeriod = frequency.shouldSuggestWeekly ? .weekly : .daily
      let targetMinutes = timePeriod == .weekly ? (frequency.averageInstancesPerWeek * 25.0) : 20.0
      
      return SuggestedGoal(
        metric: .highIntensityIntervalTrainingDuration,
        timePeriod: timePeriod,
        value: targetMinutes.roundedToNiceNumber(),
        unit: .min,
        notes: "Continue your HIIT training routine"
      )
      
    case let type where cardioTypes.contains(type):
      let timePeriod: SuggestedGoal.TimePeriod = frequency.shouldSuggestDaily ? .daily : .weekly
      let targetMinutes = frequency.shouldSuggestDaily ? 30.0 : (frequency.averageInstancesPerWeek * 40.0)
      
      return SuggestedGoal(
        metric: .cardioDuration,
        timePeriod: timePeriod,
        value: targetMinutes.roundedToNiceNumber(),
        unit: .min,
        notes: "Build on your cardio routine"
      )
      
    default:
      return nil
    }
  }
  
  func suggestActivityGoals(from pattern: UserHealthPattern) async -> [SuggestedGoal] {
    var goals = [SuggestedGoal]()
    
    if pattern.averageStepsPerDay > 2000 {
      let targetSteps = calculateStepGoal(currentAverage: pattern.averageStepsPerDay)
      goals.append(SuggestedGoal(
        metric: .stepCount,
        timePeriod: .daily,
        value: targetSteps.roundedToNiceNumber(),
        unit: .steps,
        notes: "Increase your daily steps from your current \(Int(pattern.averageStepsPerDay)) average"
      ))
    }
    
    if pattern.averageExerciseMinutesPerWeek < 150, pattern.activityLevel == .sedentary || pattern.activityLevel == .light {
      goals.append(SuggestedGoal(
        metric: .exerciseMinutes,
        timePeriod: .weekly,
        value: 120.0.roundedToNiceNumber(),
        unit: .min,
        notes: "Start building a regular exercise routine with 2 hours per week"
      ))
    }
    
    return goals
  }
  
  func suggestWellnessGoals(from pattern: UserHealthPattern) async -> [SuggestedGoal] {
    var goals = [SuggestedGoal]()
    
    if !pattern.hasRegularMeditationPractice {
      goals.append(SuggestedGoal(
        metric: .meditationMinutes,
        timePeriod: .daily,
        value: 10.0.roundedToNiceNumber(),
        unit: .min,
        notes: "Start a daily mindfulness practice with 10 minutes"
      ))
    } else if pattern.averageMeditationMinutesPerWeek > 0 && pattern.averageMeditationMinutesPerWeek < 70 {
      let targetMinutes = min(pattern.averageMeditationMinutesPerWeek + 20, 105)
      goals.append(SuggestedGoal(
        metric: .meditationMinutes,
        timePeriod: .weekly,
        value: targetMinutes.roundedToNiceNumber(),
        unit: .min,
        notes: "Expand your meditation practice from \(Int(pattern.averageMeditationMinutesPerWeek)) to \(Int(targetMinutes.roundedToNiceNumber())) minutes per week"
      ))
    }
    
    return goals
  }
  
  func calculateStepGoal(currentAverage: Double) -> Double {
    let target: Double
    switch currentAverage {
    case 0..<3000:
      target = 5000
    case 3000..<6000:
      target = currentAverage + 2000
    case 6000..<8000:
      target = 8000
    case 8000..<10000:
      target = 10000
    case 10000..<12000:
      target = 12000
    default:
      target = currentAverage + 1000
    }
    return target.roundedToNiceNumber()
  }
  
  func getDefaultOnboardingGoals() -> [SuggestedGoal] {
    return [
      SuggestedGoal(
        metric: .stepCount,
        timePeriod: .daily,
        value: 5000.0.roundedToNiceNumber(),
        unit: .steps,
        notes: "A great daily step goal to get started with an active lifestyle"
      ),
      SuggestedGoal(
        metric: .exerciseMinutes,
        timePeriod: .weekly,
        value: 150.0.roundedToNiceNumber(),
        unit: .min,
        notes: "Meet the recommended 150 minutes of exercise per week"
      )
    ]
  }
}
