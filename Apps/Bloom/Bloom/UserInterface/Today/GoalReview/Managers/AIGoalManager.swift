//
//  AIGoalManager.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-03-01.
//

import Foundation
import DataContainer
import HealthKit
import AppFoundations

final actor AIGoalManager {
  static let shared = AIGoalManager()

  private let modelActor = HabitModelActor.standard()
}

extension AIGoalManager {

  func proposeNewGoals() async throws -> ProposedGoalsResult {
    let result = try await asyncThrowingParallelize {
      try await self.calculateNewGoalsWithAI()
    } task2: {
      await self.calculateNutritionGoals()
    }

    var allGoals = [ProposedGoal]()
    var allToDos = [ProposedToDo]()

    if let nutritionGoals = result.1 {
      allGoals.append(contentsOf: nutritionGoals.0)
      allToDos.append(contentsOf: nutritionGoals.1)
    }

    if let aiGoals = result.0 {
      allGoals.append(contentsOf: aiGoals)
    }

    let allTargetMetrics = allGoals.map { $0.targetMetric }
    let removedGoals = try await calculateRemovedGoals(excluding: allTargetMetrics)

    return ProposedGoalsResult(
      goals: allGoals,
      removedGoals: removedGoals,
      todos: allToDos
    )
  }
}

private extension AIGoalManager {

  func calculateNewGoalsWithAI() async throws -> [ProposedGoal] {
    let healthData = try await ChatVitalConverter.shared.convertHealthDataString()
    let currentGoals = try await ChatGoalConverter.shared.convertGoalDataString()
    let response = try await NetworkRequester.shared.suggestGoals(healthData: healthData, currentGoals: currentGoals)

    var proposedGoals = [ProposedGoal]()
    for goal in response.goals {
      guard let habit = try await modelActor.fetchActiveHabits(for: goal.metric.targetMetric).first else { continue }

      let proposedGoal = ProposedGoal(
        habitID: habit.id,
        targetMetric: goal.metric.targetMetric,
        value: habit.isUserEdited ? habit.value : goal.value,
        suggestedValue: goal.value,
        previousValue: habit.value,
        unitString: habit.unitString,
        vitalKind: nil,
        context: goal.notes,
        hasUserEdited: habit.isUserEdited
      )
      proposedGoals.append(proposedGoal)
    }
    return proposedGoals
  }

  func calculateNutritionGoals() async -> ([ProposedGoal], [ProposedToDo])? {
    var todos = [ProposedToDo]()
    // Ensure the user has logged their weight
    if await VitalsCalculator.shared.bodyCompositionSummary?.details.averageBodyMass == nil {
      let todo = ProposedToDo(
        todoKind: .logWeight,
        todoCadence: .daily,
        vitalKind: .nutrition,
        context: "Bloom needs more data before it can suggest a focus area. Please log your weight."
      )
      todos.append(todo)
    }

    // Ensure we have enough food logged
    if await VitalsCalculator.shared.nutritionSummary?.details.hasSufficientNutritionLogs == false {
      let todo = ProposedToDo(
        todoKind: .logFood,
        todoCadence: .daily,
        vitalKind: .nutrition,
        context: "Bloom needs more data before it can suggest a focus area. Please log your food for at least 7 days."
      )
      todos.append(todo)
    } else if await VitalsCalculator.shared.nutritionSummary?.details.hasSufficientProteinLogs == false {
      let todo = ProposedToDo(
        todoKind: .logProtein,
        todoCadence: .daily,
        vitalKind: .nutrition,
        context: "Bloom needs more data before it can suggest a focus area. Please ensure you're logging protein for at least 7 days."
      )
      todos.append(todo)
    }

    if todos.isNotEmpty {
      return ([], todos)
    }

    guard
      let bodyMass = await VitalsCalculator.shared.bodyCompositionSummary?.details.averageBodyMass
    else {
      print("We should never get here.")
      return nil
    }

    if await HealthManager.shared.hasMetWeightGoal(for: bodyMass) {
      return nil
    }

    var goals = [ProposedGoal]()

    // Calories
    let existingCalorieHabit = (try? await modelActor.fetchActiveHabits(for: .calories).first)
    let newCalorieGoal: HKQuantity?

    let age = await HealthManager.shared.age()
    let sex = await HealthManager.shared.sex()
    let height = await HealthManager.shared.height()
    let userReportedActivityLevel = await HealthManager.shared.userReportedActivityLevel ?? .sedentary
    let targetDetails = await HealthManager.shared.healthTargetDetails

    let calorieTargetCalculator = CalorieTargetCalculator(
      age: age,
      sex: sex,
      bodyMass: bodyMass,
      height: height,
      activityLevel: userReportedActivityLevel,
      targetDetails: targetDetails
    )

    if let recommendation = await calorieTargetCalculator.targetCalories(existingHabit: existingCalorieHabit) {
      let suggestedValue = recommendation.target.doubleValue(for: .largeCalorie())
      let value: Double
      if let existingCalorieHabit, existingCalorieHabit.isUserEdited == true {
        value = existingCalorieHabit.value
      } else {
        value = suggestedValue
      }

      let calorieHabit = ProposedGoal(
        habitID: existingCalorieHabit?.id,
        targetMetric: .calories,
        value: value,
        suggestedValue: suggestedValue,
        previousValue: existingCalorieHabit?.value,
        unitString: HKUnit.largeCalorie().unitString,
        vitalKind: .nutrition,
        context: recommendation.context,
        hasUserEdited: existingCalorieHabit?.isUserEdited == true
      )
      goals.append(calorieHabit)
      newCalorieGoal = recommendation.target
    } else {
      newCalorieGoal = nil
    }

    // Protein
    let existingProteinHabit = (try? await modelActor.fetchActiveHabits(for: .proteinIntake).first)

    if let newCalorieGoal {
      let proteinTargetCalculator = ProteinTargetCalculator(
        calorieGoal: newCalorieGoal,
        targetDetails: targetDetails
      )

      let recommendation = await proteinTargetCalculator.targetProtein(existingHabit: existingProteinHabit)
      let suggestedValue = recommendation.target.doubleValue(for: .gram())
      let value: Double
      if let existingProteinHabit, existingProteinHabit.isUserEdited == true {
        value = existingProteinHabit.value
      } else {
        value = suggestedValue
      }

      let proteinHabit = ProposedGoal(
        habitID: existingProteinHabit?.id,
        targetMetric: .proteinIntake,
        value: value,
        suggestedValue: suggestedValue,
        previousValue: existingProteinHabit?.value,
        unitString: HKUnit.gram().unitString,
        vitalKind: .nutrition,
        context: recommendation.context,
        hasUserEdited: existingProteinHabit?.isUserEdited == true
      )
      goals.append(proteinHabit)
    }

    guard goals.isNotEmpty else { return nil }

    return (goals, [])
  }

  func calculateRemovedGoals(excluding targetMetrics: [TargetMetric]) async throws -> [ProposedGoal] {
    let activeGoals = try await modelActor.fetchActiveHabits()
    let removedGoals = activeGoals.filter({ !targetMetrics.contains($0.targetMetric) })

    return removedGoals.map { goal in
      ProposedGoal(
        habitID: goal.id,
        targetMetric: goal.targetMetric,
        value: goal.value,
        suggestedValue: goal.value,
        previousValue: goal.value,
        unitString: goal.unitString,
        vitalKind: nil,
        context: nil,
        hasUserEdited: goal.isUserEdited
      )
    }
  }
}
