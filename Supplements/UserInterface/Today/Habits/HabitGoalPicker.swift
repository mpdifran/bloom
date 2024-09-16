//
//  HabitGoalPicker.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-09.
//

import SwiftUI
import AppUI

struct HabitGoalPicker: View {

    let onHabit: (HabitModel) -> Void

    @ObservedObject private var goalsViewModel = GoalsViewModel.shared

    @State private var selectedMetric: HabitModel.MeasurementMetric?
    @State private var value: Double = 0

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if let selectedMetric {
                    Section {
                        HStack {
                            TextField("", value: $value, formatter: NumberFormatter.noDecimalPlaces)
                                .selectAllTextOnBeginEditing()
                            Text(selectedMetric.unit.unitString)
                        }
                        .fontDesign(.rounded)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .font(.largeTitle)
                        .bold()
                        .multilineTextAlignment(.trailing)
                        .horizontallyCentered()
                    }
                }

                ForEach(goalsViewModel.notYetAddedHabits()) { metric in
                    HabitMetricCell(habitMetric: metric, isSelected: selectedMetric == metric)
                        .onTapGesture {
                            selectedMetric = metric
                        }
                }
            }
            .navigationTitle("Pick a Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .shelf {
                ProminentButton("Create Habit") {
                    guard let metric = selectedMetric else { return }

                    let habit = HabitModel(measurement: metric, value: value)
                    onHabit(habit)
                    dismiss()
                }
                .disabled(selectedMetric == nil || value < 1)
            }
        }
        .animation(.default, value: selectedMetric)
    }
}

#Preview {
    HabitGoalPicker { _ in

    }
}
