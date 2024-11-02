//
//  HabitTargetValueEditCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-01.
//

import SwiftUI
import AppUI
import HealthKit
import SwiftData
import DataContainer

struct HabitTargetValueEditCardView: View {

    private let habit: Habit
    @State private var targetValue: Double
    private let onUpdate: (Habit) -> Void


    init(habit: Habit, onUpdate: @escaping (Habit) -> Void) {
        self.habit = habit
        self._targetValue = State(initialValue: habit.value)
        self.onUpdate = onUpdate
    }

    @State private var error: Error?

    @FocusState private var isFocused: Bool

    @Environment(\.dismiss) private var dismiss

    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()

                HStack {
                    TextField("", value: $targetValue, formatter: habit.targetMetric.preferredFormatter)
                        .selectAllTextOnBeginEditing()
                        .focused($isFocused)
                    Text(habit.unit.sensibleUnitString)
                }
                .fontDesign(.rounded)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.trailing)
                .padding()
                .padding(.horizontal, 30)

                Spacer()
            }
            .background {
                Rectangle()
                    .fill(.tint.tertiary)
                    .ignoresSafeArea()
            }
            .navigationTitle(habit.targetMetric.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                }
            }
            .shelf {
                ProminentButton("Save") {
                    do {
                        try save()
                        dismiss()
                    } catch {
                        self.error = error
                    }
                }
            }
        }
        .alert(error: $error)
        .presentationDetents([.height(300)])
        .presentationCornerRadius(25)
        .tint(habit.targetMetric.color)
    }
}

private extension HabitTargetValueEditCardView {

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
            habit.isUserEdited = isUserEdited
            updatedHabit = habit
        } else {
            let newHabit = habit.duplicate()

            habit.endDate = .now

            newHabit.startDate = .now
            newHabit.value = targetValue
            newHabit.isUserEdited = isUserEdited

            modelContext.insert(newHabit)

            updatedHabit = newHabit
        }

        try modelContext.save()

        onUpdate(updatedHabit)
    }
}

#Preview {
    struct PreviewView: View {

        @State private var showSheet = true
        private let habit = Habit(
            targetMetric: .bikeDistance,
            value: 5,
            unitString: HKUnit.meterUnit(with: .kilo).unitString,
            startDate: .now,
            isSuggested: true,
            isUserEdited: false
        )

        var body: some View {
            Button {
                showSheet.toggle()
            } label: {
                Text("Show Sheet")
            }
            .sheet(isPresented: $showSheet) {
                HabitTargetValueEditCardView(habit: habit) { (_) in

                }
            }
        }
    }
    return PreviewView()
}
