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

struct NewGoalCard: View {

  @State private var targetMetric: TargetMetric = .stepCount
  @State private var value: Double = 0
  @State private var unit: HKUnit = TargetMetric.stepCount.defaultUnit
  @State private var excludedTargetMetrics: [TargetMetric] = []
  @State private var didSave = false
  @State private var didError = false
  @State private var error: Error?

  @Environment(\.modelContext) private var modelContext
  @Environment(\.dismiss) private var dismiss

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

            LabeledContent("Value") {
              HStack {
                TextField("", value: $value, formatter: targetMetric.preferredFormatter)
                  .selectAllTextOnBeginEditing()
                  .frame(maxWidth: 100)

                LocalizedUnitPickerView(unit: $unit)
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
    .alert(error: $error)
    .onChange(of: targetMetric) { _, newValue in
      self.unit = newValue.defaultUnit
      self.value = targetMetric.minHabitTarget.doubleValue(for: unit)
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

    let habit = Habit(
      targetMetric: targetMetric,
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
      dismiss()
    } catch {
      self.didError.toggle()
      self.error = error
    }
  }
}

#Preview {
  PreviewSheetPresent {
    NewGoalCard()
  }
}
