//
//  NewGoalCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-25.
//

import SwiftUI
import DataContainer
import SwiftData
import HealthKit
import AppUI
import BloomFoundation

struct NewGoalCard: View {

  @State private var targetMetric: TargetMetric = .stepCount
  @State private var timePeriod: GoalTimePeriod = .daily
  @State private var value: Double = 0
  @State private var unit: HKUnit = TargetMetric.stepCount.defaultUnit
  @State private var excludedTargetMetrics: [TargetMetric] = []
  @State private var didSave = false
  @State private var didError = false
  @State private var error: Error?
  @State private var presentedSheet: AnyView?

  @Environment(\.modelContext) private var modelContext
  @Environment(\.requestReview) private var requestReview
  @Environment(\.dismiss) private var dismiss
  @ObservedObject private var entitlementController = EntitlementController.shared

  var body: some View {
    CardView {
      LargeTitleActionCard("New Goal") {
        VStack {
          VStack {
            LabeledContent("Metric") {
              TargetMetricPicker(
                selectedTargetMetric: $targetMetric,
                excludedTargetMetrics: excludedTargetMetrics
              )
            }
            .frame(minHeight: 50)

            Divider()

            LabeledContent("Period") {
              GoalTimePeriodPicker(
                selectedTimePeriod: $timePeriod,
                targetMetric: targetMetric
              )
            }
            .tint(targetMetric.color)
            .frame(minHeight: 50)

            Divider()

            LabeledContent("Value") {
              HStack {
                TextField("", value: $value, formatter: targetMetric.preferredFormatter)
                  .selectAllTextOnBeginEditing()
                  .frame(maxWidth: 100)

                LocalizedUnitPickerView(unit: $unit)
                  .tint(targetMetric.color)
              }
              .fontDesign(.rounded)
              .keyboardType(.decimalPad)
              .textFieldStyle(.roundedBorder)
              .bold()
              .multilineTextAlignment(.trailing)
            }
            .frame(minHeight: 50)
          }
          .cardContainer()

          Button {
            saveNewGoal()
          } label: {
            Text("Create")
              .horizontallyCentered()
          }
          .buttonStyle(.primary)
          .tint(targetMetric.color)
          .sensoryFeedback(.success, trigger: didSave)
          .sensoryFeedback(.error, trigger: didError)
          .disabled(!canSave)
          .padding(.top)
          .padding(.top)
        }
      }
    }
    .task {
      await loadExcludedTargetMetrics()
    }
    .sheet($presentedSheet)
    .alert(error: $error)
    .onChange(of: targetMetric) { _, newValue in
      self.unit = newValue.defaultUnit
      self.value = targetMetric.minHabitTarget.doubleValue(for: unit)

      if !targetMetric.supportedTimePeriods.contains(where: { $0 == timePeriod }) {
        timePeriod = targetMetric.supportedTimePeriods.first ?? .daily
      }
    }
    .onChange(of: excludedTargetMetrics) { _, _ in
      updateToValidTargetMetric()
    }
  }
}

private extension NewGoalCard {

  func loadExcludedTargetMetrics() async {
    do {
      let modelActor = HabitModelActor.standard()
      let habits = try await modelActor.fetchActiveHabits()
      let excludedMetrics = habits.map { $0.targetMetric }

      await MainActor.run {
        self.excludedTargetMetrics = excludedMetrics
      }
    } catch {
      print(error)
    }
  }

  func updateToValidTargetMetric() {
    let selectableMetrics = TargetMetric.userSelectableMetrics(excluding: excludedTargetMetrics)
    let metric = selectableMetrics.first ?? .stepCount

    targetMetric = metric
    unit = metric.defaultUnit
  }

  var canSave: Bool {
    value >= 1
  }

  func saveNewGoal() {
    guard canSave else { return }

    // Check if user has reached their goal limit
    let currentHabitCount = (try? modelContext.fetch(FetchDescriptor<Habit>(predicate: #Predicate<Habit> { $0.endDate == nil })).count) ?? 0
    
    if let maxGoals = entitlementController.maxGoals, currentHabitCount >= maxGoals {
      // Show paywall if at limit
      presentedSheet = BloomPlusPaywall {
        // After successful purchase, try saving again
        if entitlementController.hasBloomPro == true {
          Task {
            await Delay(300)
            saveNewGoalWithoutCheck()
          }
        }
      }.asAny
      return
    }
    
    saveNewGoalWithoutCheck()
  }
  
  private func saveNewGoalWithoutCheck() {
    let habit = Habit(
      targetMetric: targetMetric,
      timePeriod: timePeriod,
      value: value,
      unitString: unit.unitString,
      startDate: .now,
      isSuggested: false,
      isUserEdited: true
    )
    modelContext.insert(habit)

    do {
      try modelContext.save()
      didSave.toggle()

      if RatingPromptTracker.shared.recordEvent() {
        requestReview()
      }

      dismiss()
    } catch {
      self.didError.toggle()
      self.error = error
    }
  }
}

#Preview {
  PreviewEnvironment {
    PreviewSheetPresent {
      NewGoalCard()
    }
  }
}
