//
//  EditUserAddedHabitView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-29.
//

import SwiftUI
import AppUI
import DataContainer
import HealthKit

struct EditUserAddedHabitView: View {
  private let habit: Habit
  private let canDelete: Bool
  private let onUpdate: (Habit?) -> Void

  @State private var targetValue: Double
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
    self._unit = State(initialValue: habit.unit)
  }

  @State private var didSaveToggle = false
  @State private var confirmationDialogDetails: ConfirmationDialogDetails?
  @State private var error: Error?

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
              Image(systemName: "trash")
                .bold()
                .font(.title3)
                .foregroundStyle(.mutedRed)
                .padding(6)
            }
            .zStackAlignment(.trailing)
          }
        }

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
        .cardContainer()
        .padding(.vertical)
        .padding(.bottom)

        Button {
          do {
            try save()
            dismiss()
          } catch {
            self.error = error
          }
        } label: {
          Text("Save")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
        .sensoryFeedback(.success, trigger: didSaveToggle)
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
    let updatedHabit: Habit
    let isUserEdited: Bool
    if !habit.isUserEdited {
      isUserEdited = !habit.value.isWithinRange(of: targetValue, precision: 1)
    } else {
      isUserEdited = true
    }

    if Calendar.current.isDateInToday(habit.startDate) {
      habit.value = targetValue
      habit.unitString = unit.unitString
      habit.isUserEdited = isUserEdited
      updatedHabit = habit
    } else {
      let newHabit = habit.duplicate()

      habit.endDate = .now

      newHabit.startDate = .now
      newHabit.value = targetValue
      newHabit.unitString = unit.unitString
      newHabit.isUserEdited = isUserEdited

      modelContext.insert(newHabit)

      updatedHabit = newHabit
    }

    try modelContext.save()
    didSaveToggle.toggle()

    onUpdate(updatedHabit)
  }

  func promptDelete() {
    confirmationDialogDetails = .init(
      title: "Are You Sure?",
      message: "This can't be undone",
      buttons: [
        .init(title: "Delete", role: .destructive) {
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
    habit.endDate = .now

    try modelContext.save()

    onUpdate(nil)
  }
}

#Preview {
  @Previewable @State var habit = Habit(
    targetMetric: .bikeDistance,
    value: 10,
    unitString: "km",
    startDate: .now,
    isSuggested: true,
    isUserEdited: false
  )

  PreviewSheetPresent {
    EditUserAddedHabitView(habit: habit) { _ in

    }
  }
}
