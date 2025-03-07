//
//  ProposedHabitTargetValueEditCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-20.
//

import SwiftUI
import AppUI
import HealthKit
import SwiftData

struct ProposedHabitTargetValueEditCardView: View {
  @Binding var proposedHabit: ProposedGoal
  @State private var value: Double
  @State private var unit: HKUnit

  init(proposedHabit: Binding<ProposedGoal>) {
    self._proposedHabit = proposedHabit
    self._value = State(initialValue: proposedHabit.wrappedValue.value)
    self._unit = State(initialValue: proposedHabit.wrappedValue.unit)
  }

  @FocusState private var isFocused: Bool

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    NavigationStack {
      VStack {
        Spacer()

        HStack {
          TextField("", value: $value, formatter: proposedHabit.targetMetric.preferredFormatter)
            .selectAllTextOnBeginEditing()
            .focused($isFocused)

          LocalizedUnitPickerView(unit: $unit)
        }
        .fontDesign(.rounded)
        .keyboardType(.decimalPad)
        .textFieldStyle(.roundedBorder)
        .font(.largeTitle)
        .bold()
        .multilineTextAlignment(.trailing)
        .padding()
        .padding(.horizontal, 30)

        if proposedHabit.shouldShowSuggestedValue {
          Text("Recommended \(proposedHabit.displaySuggestedValue)")
            .bold()
        }

        if let previousQuantity = proposedHabit.displayPreviousQuantity {
          Text("Previously \(previousQuantity)")
            .foregroundStyle(.secondary)
            .font(.caption)
        }

        Spacer()
      }
      .background {
        Rectangle()
          .fill(.tint.tertiary)
          .ignoresSafeArea()
      }
      .navigationTitle(proposedHabit.targetMetric.name)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel", role: .cancel) {
            dismiss()
          }
        }
      }
      .shelf {
        Button {
          proposedHabit.value = value
          proposedHabit.unitString = unit.unitString
          proposedHabit.hasUserEdited = true
          dismiss()
        } label: {
          Text("Save")
            .horizontallyCentered()
        }
        .buttonStyle(.primary)
      }
    }
    .presentationDetents([.height(300)])
    .presentationCornerRadius(25)
  }
}

#Preview {
  @Previewable @State var proposedGoal = ProposedGoal(
    habitID: nil,
    targetMetric: .stepCount,
    value: 3000,
    suggestedValue: 5000,
    previousValue: 2000,
    unitString: HKUnit.count().unitString,
    vitalKind: .heartHealth,
    context: "",
    hasUserEdited: true
  )

  PreviewSheetPresent {
    ProposedHabitTargetValueEditCardView(proposedHabit: $proposedGoal)
      .tint(.mutedBlue)
  }
}
