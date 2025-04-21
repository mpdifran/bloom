//
//  EditUserAddedHabitView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-29.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import DataContainer
import HealthKit

struct EditUserAddedHabitView: View {
  private let habit: Habit
  private let canDelete: Bool
  private let onUpdate: (Habit?) -> Void

  @State private var targetValue: Double
  @State private var timePeriod: GoalTimePeriod
  @State private var unit: HKUnit

  init(
    habit: Habit,
    canDelete: Bool = true,
    onUpdate: @escaping (Habit?) -> Void
  ) {
    self.habit = habit
    self.canDelete = canDelete
    self.onUpdate = onUpdate
    self._targetValue = State(initialValue: habit.value)
    self._timePeriod = State(initialValue: habit.timePeriod)
    self._unit = State(initialValue: habit.unit)
  }

  @State private var didSaveToggle = false
  @State private var confirmationDialogDetails: ConfirmationDialogDetails?
  @State private var error: Error?

  @ObservedObject private var habitsViewModel = HabitsViewModel.shared

  @FocusState private var isFocused: Bool
  @Environment(\.dismiss) private var dismiss
  @Environment(\.modelContext) private var modelContext

  var body: some View {
    ScrollView {
      VStack {
        ZStack {
          Text(habit.targetMetric.name)
            .bold()
            .padding(10)
            .zStackAlignment(.center)

          if canDelete {
            Button {
              promptDelete()
            } label: {
              Image(systemSymbol: .trash)
                .bold()
                .font(.title3)
                .foregroundStyle(.mutedRed)
                .padding(6)
            }
            .zStackAlignment(.trailing)
          }
        }

        VStack {
          LabeledContent("Value") {
            HStack {
              TextField("", value: $targetValue, formatter: habit.targetMetric.preferredFormatter)
                .selectAllTextOnBeginEditing()
                .frame(maxWidth: 100)
                .focused($isFocused)

              LocalizedUnitPickerView(unit: $unit)
            }
            .fontDesign(.rounded)
            .keyboardType(.decimalPad)
            .textFieldStyle(.roundedBorder)
            .bold()
            .multilineTextAlignment(.trailing)
          }
          .frame(minHeight: 50)

          Divider()

          LabeledContent("Period") {
            GoalTimePeriodPicker(
              selectedTimePeriod: $timePeriod,
              targetMetric: habit.targetMetric
            )
            .fontDesign(.rounded)
            .bold()
          }
        }
        .cardContainer()
        .padding(.vertical)


        AsyncButton {
          try save()
          dismiss()
        } label: {
          Text("Save")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .sensoryFeedback(.success, trigger: didSaveToggle)
        .padding(.top)
      }
      .padding()
      .presentationDetentSelfSizing()
    }
    .presentationCornerRadius(30)
    .presentationDragIndicator(.visible)
    .confirmationDialog($confirmationDialogDetails)
    .alert(error: $error)
    .groupedBackground()
    .tint(habit.targetMetric.color)
  }
}

private extension EditUserAddedHabitView {

  func save() throws {
    let newHabit = try habitsViewModel.update(
      timePeriod: timePeriod,
      value: targetValue,
      unit: unit,
      for: habit
    )
    didSaveToggle.toggle()

    onUpdate(newHabit)
  }

  func promptDelete() {
    confirmationDialogDetails = ConfirmationDialogDetails(
      title: "Are You Sure?",
      message: "This can't be undone",
      buttons: [
        ConfirmationDialogDetails.Button(title: "Delete", role: .destructive) {
          do {
            try delete()
            dismiss()
          } catch {
            self.error = error
          }
        }
      ]
    )
  }

  func delete() throws {
    try habitsViewModel.delete(habit)
    onUpdate(nil)
  }
}

#Preview {
  @Previewable @State var habit = Habit(
    targetMetric: .bikeDistance,
    timePeriod: .daily,
    value: 10,
    unitString: "km",
    startDate: .now,
    isSuggested: true,
    isUserEdited: false
  )

  PreviewEnvironment {
    PreviewSheetPresent {
      EditUserAddedHabitView(habit: habit) { _ in

      }
    }
  }
}
