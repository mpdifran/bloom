//
//  HabitsFactory.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-23.
//

import Foundation
import SwiftData
import DataContainer
import HealthKit
import TelemetryDeck

final actor HabitsFactory {
  static let shared = HabitsFactory()

  private init() { }
}

extension HabitsFactory {

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

extension HabitsFactory {

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

private extension HabitsFactory {

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
      let bodyMass = await VitalsCalculator.shared.bodyCompositionSummary?.details.averageBodyMass,
      let averageDietaryEnergy = await VitalsCalculator.shared.nutritionSummary?.details.dietaryEnergy
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
    let userReportedActivityLevel = await HealthManager.shared.userReportedActivityLevel ?? .sedentary

    let existingCalorieHabit = activeHabits.first(where: { $0.targetMetric == .calories })
    let newCalorieGoal: HKQuantity?

    if let recommendation = await CalorieTargetCalculator.targetCalories(
      existingHabit: existingCalorieHabit,
      dietaryEnergy: averageDietaryEnergy,
      bodyMass: bodyMass,
      activityLevel: userReportedActivityLevel,
      targetDetails: HealthManager.shared.healthTargetDetails
    ) {
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
      newFocusAreas.append(calorieHabit)
      newCalorieGoal = recommendation.target
    } else {
      newCalorieGoal = nil
    }

    // Protein
    let existingProteinHabit = activeHabits.first(where: { $0.targetMetric == .proteinIntake })
    if
      let newCalorieGoal,
      let averageProtein = await VitalsCalculator.shared.nutritionSummary?.details.averageProtein,
      let recommendation = await ProteinTargetCalculator.targetProtein(
        existingHabit: existingProteinHabit,
        protein: averageProtein,
        dietaryEnergy: averageDietaryEnergy,
        calorieGoal: newCalorieGoal,
        targetDetails: HealthManager.shared.healthTargetDetails
      )
    {
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
      newFocusAreas.append(proteinHabit)
    }

    if newFocusAreas.isNotEmpty {
      let focusVitals = newFocusAreas.map({ FocusVital(vitalKind: .nutrition, proposedGoals: [$0]) })
      return NewHabitResult(focusVitals: focusVitals)
    }
    return nil
  }
}

private extension HabitsFactory {

  func generateFocusVital(for vital: VitalModel) async -> FocusVital {
    let goalOptions = await createGoalOptions(for: vital.id)

    // TODO: Optimize the order of the options here to be more personable.
    return FocusVital(vitalKind: vital.id, proposedGoals: goalOptions)
  }

  func createGoalOptions(for vitalKind: VitalModel.Kind) async -> [ProposedGoal] {
    switch vitalKind {
    case .heartHealth:
      return [
        await createHabit(
          targetMetric: .walkingRunningDistance,
          unit: .meterUnit(with: .kilo),
          vitalKind: vitalKind,
          context: "Walking or running more can help improve your heart health."
        )
      ]
    case .sleepQuality:
      return []
    case .activityLevel:
      return [
        await createHabit(
          targetMetric: .stepCount,
          unit: .count(),
          vitalKind: vitalKind,
          context: "Getting your steps in is an easy way to increase your activity level."
        )
      ]
    case .stressLevels:
      return [
        await createHabit(
          targetMetric: .meditationMinutes,
          unit: .minute(),
          vitalKind: vitalKind,
          context: "Meditation is a great way to lower stress levels."
        )
      ]
    case .exerciseEffectiveness:
      return [
        await createHabit(
          targetMetric: .exerciseMinutes,
          unit: .minute(),
          vitalKind: vitalKind,
          context: "Getting any type of exercise will help you get more zone minutes."
        ),
        await createHabit(
          targetMetric: .runDistance,
          unit: .meterUnit(with: .kilo),
          vitalKind: vitalKind,
          context: "Running is a great way to spend time in different target heart rate zones."
        ),
        await createHabit(
          targetMetric: .targetHeartRateZone1,
          unit: .minute(),
          vitalKind: vitalKind,
          context: "Zone 1 is the easiest way to get your zone minutes."
        ),
        await createHabit(
          targetMetric: .targetHeartRateZone2,
          unit: .minute(),
          vitalKind: vitalKind,
          context: "Zone 2 is a bit more intense than Zone 1, but still a good way to get your zone minutes."
        ),
        await createHabit(
          targetMetric: .targetHeartRateZone3,
          unit: .minute(),
          vitalKind: vitalKind,
          context: "Zone 3 is moderately intense, but every minute spent here is worth 2x the zone minutes."
        ),
        await createHabit(
          targetMetric: .targetHeartRateZone4,
          unit: .minute(),
          vitalKind: vitalKind,
          context: "Zone 4 is a bit more intense than Zone 3, but still gets 2x the zone minutes."
        ),
        await createHabit(
          targetMetric: .targetHeartRateZone5,
          unit: .minute(),
          vitalKind: vitalKind,
          context: "Zone 5 is the most intense zone, which is why every minute is worth 3x the zone minutes!"
        )
      ]
    case .bowelMovements:
      return [
        await createHabit(
          targetMetric: .waterIntake,
          unit: .literUnit(with: .milli),
          vitalKind: vitalKind,
          context: "Staying hydrated can help make your bowel movements more regular."
        )
      ]
    case .bodyComposition, .cycleTracking, .nutrition, .cardioFitness:
      return []
    @unknown default:
      return []
    }
  }

  func updatedHabit(for habit: HabitDTO) async -> ProposedGoal? {

    // Cardio Fitness is now Heart Health
    guard habit.vitalKind != .cardioFitness else { return nil }

    // TODO: Determine when to promote to Habit from Focus Area
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

private extension HabitsFactory {

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

    // TODO: Optimize this by sharing the model actor.
    let modelActor = HabitModelActor.standard()
    let existingGoal = (try? await modelActor.fetchActiveHabits(for: targetMetric))?.first

    if let existingGoal {
      // Calculate what the recommendation should be.
      if let recommendation = await GenericHabitTargetCalculator.calculateNewTarget(habit: existingGoal) {
        suggestedValue = recommendation.target.doubleValue(for: existingGoal.unit)
        value = suggestedValue
        resolvedContext = recommendation.context
      }

      // If it's been used edited, don't change the value.
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
