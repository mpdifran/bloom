//
//  GoalsFactory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-23.
//

import Foundation
import SwiftData
import DataContainer
import HealthKit
import TelemetryDeck

final actor GoalsFactory {
  static let shared = GoalsFactory()

  private init() { }

  private let activityLevelGoalFactory = ActivityLevelGoalFactory()
  private let bowelMovementGoalFactory = BowelMovementGoalFactory()
  private let exerciseEffectivenessGoalFactory = ExerciseEffectivenessGoalFactory()
  private let heartHealthGoalFactory = HeartHealthGoalFactory()
  private let sleepQualityGoalFactory = SleepQualityGoalFactory()
  private let stressLevelGoalFactory = StressLevelGoalFactory()
}

extension GoalsFactory {

  func recommendedFocusVitals() async -> [VitalModel] {
    var focusVitals: [VitalModel] = []

    await VitalsCalculator.shared.forceFetchVitals()

    if
      await shouldFocusOnNutrition(),
      let vital = await VitalsCalculator.shared.vitals.first(where: { $0.id == .nutrition })
    {
      focusVitals.append(vital)
    }

    let modelActor = HabitModelActor.standard()

    for vital in await VitalsCalculator.shared.vitals {
      guard focusVitals.count < 2 else { break }

      if vital.id.supportsSuggestedGoals {
        guard !focusVitals.contains(where: { $0.id == vital.id }) else { continue }

        focusVitals.append(vital)
      }
    }

    let suggestedHabits = (try? await modelActor.fetchActiveHabits(isSuggested: true)) ?? []

    for habit in suggestedHabits {
      guard
        focusVitals.count < 2,
        let vitalKind = habit.vitalKind,
        let vital = await VitalsCalculator.shared.vitals.first(where: { $0.id == vitalKind }),
        !focusVitals.contains(where: { $0.id == vital.id })
      else { continue }

      focusVitals.append(vital)
    }

    focusVitals.sort(by: { lhs, rhs in
      guard let lhsLevel = lhs.barLevel else { return false }
      guard let rhsLevel = rhs.barLevel else { return true }

      return lhsLevel < rhsLevel
    })

    return focusVitals
  }

  private func shouldFocusOnNutrition() async -> Bool {
    if let bodyMass = await VitalsCalculator.shared.bodyCompositionSummary?.details.averageBodyMass {
      if await HealthManager.shared.hasMetWeightGoal(for: bodyMass) {
        return false
      }
      return true
    }

    switch await HealthManager.shared.healthGoal {
    case .gainWeight, .maintainWeight, .loseWeight:
      return true
    case .none:
      return false
    }
  }
}

extension GoalsFactory {

  func generateProposedHabits(vitals: [VitalModel]) async -> NewHabitResult {
    var vitals = vitals
    let modelActor = HabitModelActor.standard()
    let activeGoals = (try? await modelActor.fetchActiveHabits()) ?? []
    let userAddedGoals = activeGoals.filter({ !$0.isSuggested })

    await VitalsCalculator.shared.forceFetchVitals()

    var newHabitResult = NewHabitResult()

    if
      vitals.contains(where: { $0.id == .nutrition }),
      let nutritionHabits = await generateNutritionHabits(activeHabits: activeGoals)
    {
      newHabitResult.appendNewTargets(result: nutritionHabits)
      vitals.removeAll(where: { $0.id == .nutrition })
    }

    // Fill out habits for remaining vitals
    for vital in vitals {
      let goals = await createGoalOptions(for: vital.id)

      guard goals.isNotEmpty else { continue }

      let focusVital = FocusVital(vitalKind: vital.id, proposedGoals: goals)
      newHabitResult.focusVitals.append(focusVital)
    }

    // Update user's added habits
    for goal in userAddedGoals {
      if let newGoal = await updatedHabit(for: goal) {
        newHabitResult.proposedGoals.append(newGoal)
      }
    }

    return newHabitResult
  }
}

// MARK: - Nutrition Habits

private extension GoalsFactory {

  func generateNutritionHabits(activeHabits: [HabitDTO]) async -> NewHabitResult? {
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
      return NewHabitResult(
        proposedToDos: todos
      )
    }

    guard
      let bodyMass = await VitalsCalculator.shared.bodyCompositionSummary?.details.averageBodyMass
    else {
      print("We should never get here.")
      return nil
    }

    if await HealthManager.shared.hasMetWeightGoal(for: bodyMass) {
      var proposedHabits = [ProposedGoal]()
      if let habit = activeHabits.first(where: { $0.targetMetric == .calories }) {
        let calorieHabit = ProposedGoal(
          habitID: habit.id,
          targetMetric: .calories,
          timePeriod: .daily,
          value: habit.value,
          suggestedValue: habit.value,
          previousValue: nil,
          unitString: HKUnit.largeCalorie().unitString,
          vitalKind: .nutrition,
          context: "You've met your target weight! Let's make this a permanent habit.",
          hasUserEdited: habit.isUserEdited
        )
        proposedHabits.append(calorieHabit)
      }
      if let habit = activeHabits.first(where: { $0.targetMetric == .proteinIntake }) {
        let proteinHabit = ProposedGoal(
          habitID: habit.id,
          targetMetric: .proteinIntake,
          timePeriod: .daily,
          value: habit.value,
          suggestedValue: habit.value,
          previousValue: nil,
          unitString: HKUnit.gram().unitString,
          vitalKind: .nutrition,
          context: "You've met your target weight! Let's make this a permanent habit.",
          hasUserEdited: habit.isUserEdited
        )
        proposedHabits.append(proteinHabit)
      }

      let focusVitals = proposedHabits.map {
        FocusVital(vitalKind: .nutrition, proposedGoals: [$0])
      }

      return NewHabitResult(focusVitals: focusVitals)
    }

    var newFocusAreas = [ProposedGoal]()

    // Calories
    let existingCalorieHabit = activeHabits.first(where: { $0.targetMetric == .calories })
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
        timePeriod: .daily,
        value: value,
        suggestedValue: suggestedValue,
        previousValue: existingCalorieHabit?.value,
        unitString: HKUnit.largeCalorie().unitString,
        vitalKind: .nutrition,
        context: recommendation.context,
        hasUserEdited: existingCalorieHabit?.isUserEdited == true
      )
      newFocusAreas.append(calorieHabit)
      newCalorieGoal = recommendation.target
    } else {
      newCalorieGoal = nil
    }

    // Protein
    let existingProteinHabit = activeHabits.first(where: { $0.targetMetric == .proteinIntake })

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
        timePeriod: .daily,
        value: value,
        suggestedValue: suggestedValue,
        previousValue: existingProteinHabit?.value,
        unitString: HKUnit.gram().unitString,
        vitalKind: .nutrition,
        context: recommendation.context,
        hasUserEdited: existingProteinHabit?.isUserEdited == true
      )
      newFocusAreas.append(proteinHabit)
    }

    if newFocusAreas.isNotEmpty {
      let focusVitals = newFocusAreas.map({ FocusVital(vitalKind: .nutrition, proposedGoals: [$0]) })
      return NewHabitResult(focusVitals: focusVitals)
    }
    return nil
  }
}

private extension GoalsFactory {

  func generateFocusVital(for vital: VitalModel) async -> FocusVital {
    let goalOptions = await createGoalOptions(for: vital.id)

    // TODO: Optimize the order of the options here to be more personable.
    return FocusVital(vitalKind: vital.id, proposedGoals: goalOptions)
  }

  func createGoalOptions(for vitalKind: VitalModel.Kind) async -> [ProposedGoal] {
    switch vitalKind {
    case .heartHealth:
      return await heartHealthGoalFactory.createGoals()
    case .sleepQuality:
      return await sleepQualityGoalFactory.createGoals()
    case .activityLevel:
      return await activityLevelGoalFactory.createGoals()
    case .stressLevels:
      return await stressLevelGoalFactory.createGoals()
    case .exerciseEffectiveness:
      return await exerciseEffectivenessGoalFactory.createGoals()
    case .bowelMovements:
      return await bowelMovementGoalFactory.createGoals()
    case .bodyComposition, .cycleTracking, .nutrition, .cardioFitness:
      return []
    @unknown default:
      return []
    }
  }

  func updatedHabit(for habit: HabitDTO) async -> ProposedGoal? {

    // Cardio Fitness is now Heart Health
    guard habit.vitalKind != .cardioFitness else { return nil }

    guard let recommendation = await GenericHabitTargetCalculator.calculateNewTarget(
      habit: habit
    ) else {
      return nil
    }

    let suggestedValue = recommendation.target.doubleValue(for: habit.unit)
    let value: Double
    if habit.isUserEdited {
      value = habit.value
    } else {
      value = suggestedValue
    }

    return ProposedGoal(
      habitID: habit.id,
      targetMetric: habit.targetMetric,
      timePeriod: habit.timePeriod,
      value: value,
      suggestedValue: suggestedValue,
      previousValue: habit.value,
      unitString: habit.unitString,
      vitalKind: habit.vitalKind,
      context: recommendation.context,
      hasUserEdited: habit.isUserEdited
    )
  }
}
