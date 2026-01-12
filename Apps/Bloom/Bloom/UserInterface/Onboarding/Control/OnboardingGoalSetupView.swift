//
//  OnboardingGoalSetupView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-24.
//

import SwiftUI
import AppUI
import TelemetryDeck
import BloomModel
import HealthKit
import CoreHealth
import DataContainer
import SwiftData
import BloomUI
import BloomFoundation

struct OnboardingGoalSetupView: View {
  let onContinue: () -> Void

  @State private var index = 1
  @State private var didContinue = false
  @State private var error: Error?
  @State private var suggestedGoals = [SuggestedGoal]()
  @State private var isLoadingGoals = true
  @State private var addGoalToggle = false
  @State private var removeGoalToggle = false
  @State private var healthPattern: UserHealthPattern?
  @State private var presentedSheet: AnyView?

  @Query(filter: #Predicate<Habit> { $0.endDate == nil }, sort: \Habit.startDate) 
  private var activeHabits: [Habit]
  
  @Environment(\.modelContext) private var modelContext
  @ObservedObject private var entitlementController = EntitlementController.shared

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        BudImage(.budStrengthTraining)

        Group {
          Text("Let's set some goals!")
            .transition(.opacity)
            .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)

          Text("Goals are a great way to help improve specific aspects of your health, and keep track of the progress.")
            .font(.title3)
            .foregroundStyle(.secondary)
            .transition(.opacity)
            .appear(with: 2, currentIndex: index)

          goalSuggestionSection
        }
        .onboardingTextStyle()
      }
      .horizontalAlignment(.leading)
      .padding()
    }
    .shelf {
      if index == 2 && !isLoadingGoals {

        HStack {
          Button {
            didContinue.toggle()
            onContinue()
          } label: {
            Text("Skip")
              .horizontallyCentered()
          }
          .buttonStyle(.primaryAlternate)

          Button {
            didContinue.toggle()
            onContinue()
          } label: {
            Text("Continue")
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
        }
      }
    }
    .alert(error: $error)
    .groupedBackground()
    .animation(.default, value: index)
    .animation(.default, value: activeHabits)
    .animation(.default, value: suggestedGoals)
    .sensoryFeedback(.selection, trigger: index)
    .sensoryFeedback(.impact, trigger: didContinue)
    .sheet($presentedSheet)
    .task {
      while index < 2 {
        await advanceIndex()
      }
      await loadGoalSuggestions()
    }
    .onAppear {
      TelemetryDeck.signal("OB Goal Setup")
    }
  }
}

private extension OnboardingGoalSetupView {
  
  var filteredSuggestedGoals: [SuggestedGoal] {
    suggestedGoals.filter { goal in
      !activeHabits.contains { $0.targetMetric == goal.metric.targetMetric }
    }
  }

  func advanceIndex() async {
    await Delay(1000)

    index += 1
  }
  
  func loadGoalSuggestions() async {
    let pattern = await HealthPatternAnalyzer.shared.analyzeUserHealthPattern()
    let goals = await OnboardingGoalSuggestionService.shared.suggestGoalsForOnboarding()
    await MainActor.run {
      self.healthPattern = pattern
      self.suggestedGoals = goals
      self.isLoadingGoals = false
    }
  }

  @ViewBuilder
  var goalSuggestionSection: some View {
    if isLoadingGoals {
      VStack {
        ProgressView()
          .controlSize(.large)
        
        Text("Analyzing your personal data...")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .horizontallyCentered()
      .padding(.vertical, 40)
      .transition(.opacity)
    } else {
      VStack {
        if !activeHabits.isEmpty {
          Text(activeHabits.count == 1 ? "Your selected goal:" : "Your selected goals:")
            .font(.subheadline)
            .foregroundStyle(.secondary)

          VStack {
            ForEach(activeHabits, id: \.id) { habit in
              existingGoalCell(for: habit)
            }
          }
        }

        Text("Suggestions")
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(.top, activeHabits.isEmpty ? 0 : 20)

        ForEach(filteredSuggestedGoals, id: \.metric) { goal in
          goalCell(for: goal)
        }

        addGoalButton
      }
    }
  }
  
  func goalCell(for goal: SuggestedGoal) -> some View {
    let targetMetric = goal.metric.targetMetric
    let existingHabit = activeHabits.first { $0.targetMetric == targetMetric }
    let isSelected = existingHabit != nil
    let targetQuantity = HKQuantity(unit: goal.unit.hkUnit, doubleValue: goal.value)
    let averageQuantity = calculateAverageQuantity(for: goal)
    
    return
      OnboardingProposedGoalCell(
        targetMetric: targetMetric,
        averageQuantity: averageQuantity,
        targetQuantity: targetQuantity,
        isWeekly: goal.timePeriod == .weekly,
        hasAdded: isSelected
      )
      .transition(.blurReplace)
      .sensoryFeedback(.success, trigger: addGoalToggle)
      .sensoryFeedback(.selection, trigger: removeGoalToggle)
      .onTapGesture {
        if isSelected {
          removeGoal(existingHabit!)
        } else {
          saveGoal(goal)
        }
      }
  }
  
  func existingGoalCell(for habit: Habit) -> some View {
    let averageQuantity = calculateAverageQuantityForHabit(habit)
    let targetQuantity = HKQuantity(unit: habit.unit, doubleValue: habit.value)
    
    return
      OnboardingProposedGoalCell(
        targetMetric: habit.targetMetric,
        averageQuantity: averageQuantity,
        targetQuantity: targetQuantity,
        isWeekly: habit.timePeriod == .weekly,
        hasAdded: true
      )
      .transition(.blurReplace)
      .sensoryFeedback(.selection, trigger: removeGoalToggle)
      .onTapGesture {
        removeGoal(habit)
      }
  }

  var addGoalButton: some View {
    Button {
      showNewGoalSheet()
    } label: {
      Label("Select Another Goal", systemSymbol: .plus)
        .font(.body)
        .horizontallyCentered()
        .cardContainer()
    }
  }
  
  func saveGoal(_ suggestedGoal: SuggestedGoal) {
    let habit = Habit(
      targetMetric: suggestedGoal.metric.targetMetric,
      timePeriod: GoalTimePeriod(rawValue: suggestedGoal.timePeriod.rawValue) ?? .daily,
      value: suggestedGoal.value,
      unitString: suggestedGoal.unit.hkUnit.unitString,
      startDate: .now,
      isSuggested: false,
      isUserEdited: false
    )
    
    modelContext.insert(habit)

    do {
      try modelContext.save()
      addGoalToggle.toggle()

      // Update widget cache
      Task {
        await GoalWidgetCacheManager.shared.updateCache()
      }
    } catch {
      self.error = error
    }
  }

  func removeGoal(_ habit: Habit) {
    habit.endDate = .now

    do {
      try modelContext.save()
      removeGoalToggle.toggle()

      // Update widget cache
      Task {
        await GoalWidgetCacheManager.shared.updateCache()
      }
    } catch {
      self.error = error
    }
  }
  
  func showNewGoalSheet() {
    let currentHabitCount = activeHabits.count
    
    if let maxGoals = entitlementController.maxGoals, currentHabitCount >= maxGoals {
      EntitledPresent(presentedSheet: $presentedSheet) {
        NewGoalCard()
      }
      return
    }
    
    presentedSheet = NewGoalCard().asAny
  }

  func calculateAverageQuantity(for goal: SuggestedGoal) -> HKQuantity {
    guard let pattern = healthPattern else {
      return HKQuantity(unit: goal.unit.hkUnit, doubleValue: 0)
    }
    
    let averageValue: Double
    
    switch goal.metric {
    case .stepCount:
      averageValue = pattern.averageStepsPerDay
    case .exerciseMinutes:
      averageValue = pattern.averageExerciseMinutesPerWeek
    case .meditationMinutes:
      if goal.timePeriod == .weekly {
        averageValue = pattern.averageMeditationMinutesPerWeek
      } else {
        averageValue = pattern.averageMeditationMinutesPerWeek / 7.0
      }
    case .strengthTrainingDuration, .cardioDuration, .mobilityAndFlexibilityDuration, 
         .highIntensityIntervalTrainingDuration, .runDuration, .bikeDuration:
      averageValue = getRelevantWorkoutMinutes(for: goal.metric, from: pattern)
    default:
      averageValue = 0
    }
    
    return HKQuantity(unit: goal.unit.hkUnit, doubleValue: averageValue)
  }
  
  func calculateAverageQuantityForHabit(_ habit: Habit) -> HKQuantity {
    guard let pattern = healthPattern else {
      return HKQuantity(unit: habit.unit, doubleValue: 0)
    }
    
    let averageValue: Double
    
    switch habit.targetMetric {
    case .stepCount:
      averageValue = pattern.averageStepsPerDay
    case .exerciseMinutes:
      averageValue = pattern.averageExerciseMinutesPerWeek
    case .meditationMinutes:
      if habit.timePeriod == .weekly {
        averageValue = pattern.averageMeditationMinutesPerWeek
      } else {
        averageValue = pattern.averageMeditationMinutesPerWeek / 7.0
      }
    case .strengthTrainingDuration, .cardioDuration, .mobilityAndFlexibilityDuration, 
         .highIntensityIntervalTrainingDuration, .runDuration, .bikeDuration:
      let relevantWorkouts = getRelevantWorkoutMinutesForTargetMetric(habit.targetMetric, from: pattern)
      averageValue = relevantWorkouts
    default:
      averageValue = 0
    }
    
    return HKQuantity(unit: habit.unit, doubleValue: averageValue)
  }
  
  func getRelevantWorkoutMinutes(for metric: SuggestedGoal.Metric, from pattern: UserHealthPattern) -> Double {
    let strengthTypes = [HKWorkoutActivityType].strengthTrainingTypes
    let cardioTypes = [HKWorkoutActivityType].cardioTypes
    let mobilityTypes = [HKWorkoutActivityType].mobilityAndFlexibilityTypes
    let hiitTypes = [HKWorkoutActivityType].highIntensityIntervalTrainingTypes
    
    var relevantTypes: [HKWorkoutActivityType] = []
    
    switch metric {
    case .strengthTrainingDuration:
      relevantTypes = strengthTypes
    case .cardioDuration:
      relevantTypes = cardioTypes
    case .mobilityAndFlexibilityDuration:
      relevantTypes = mobilityTypes
    case .highIntensityIntervalTrainingDuration:
      relevantTypes = hiitTypes
    case .runDuration:
      relevantTypes = [.running]
    case .bikeDuration:
      relevantTypes = [.cycling]
    default:
      return 0
    }
    
    let relevantFrequencies = pattern.workoutFrequencyByType.filter { key, _ in
      relevantTypes.contains(key)
    }
    
    return relevantFrequencies.values.reduce(0) { $0 + $1.totalMinutesPerWeek }
  }
  
  func getRelevantWorkoutMinutesForTargetMetric(_ targetMetric: TargetMetric, from pattern: UserHealthPattern) -> Double {
    let strengthTypes = [HKWorkoutActivityType].strengthTrainingTypes
    let cardioTypes = [HKWorkoutActivityType].cardioTypes
    let mobilityTypes = [HKWorkoutActivityType].mobilityAndFlexibilityTypes
    let hiitTypes = [HKWorkoutActivityType].highIntensityIntervalTrainingTypes
    
    var relevantTypes: [HKWorkoutActivityType] = []
    
    switch targetMetric {
    case .strengthTrainingDuration:
      relevantTypes = strengthTypes
    case .cardioDuration:
      relevantTypes = cardioTypes
    case .mobilityAndFlexibilityDuration:
      relevantTypes = mobilityTypes
    case .highIntensityIntervalTrainingDuration:
      relevantTypes = hiitTypes
    case .runDuration:
      relevantTypes = [.running]
    case .bikeDuration:
      relevantTypes = [.cycling]
    default:
      return 0
    }
    
    let relevantFrequencies = pattern.workoutFrequencyByType.filter { key, _ in
      relevantTypes.contains(key)
    }
    
    return relevantFrequencies.values.reduce(0) { $0 + $1.totalMinutesPerWeek }
  }
}

#Preview {
  PreviewEnvironment {
    OnboardingGoalSetupView() { }
  }
}
