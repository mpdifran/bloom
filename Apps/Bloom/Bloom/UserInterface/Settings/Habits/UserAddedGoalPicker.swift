//
//  UserAddedGoalPicker.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-21.
//

import SwiftUI
import DataContainer
import AppUI
import SwiftData

struct UserAddedGoalPicker: View {

    @State private var selectedTargetMetric: TargetMetric?
    @State private var proposedHabit: ProposedGoal?
    @State private var showQuantitySheet = false
    @State private var error: Error?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var activeHabits: [Habit]

    init() {
        _activeHabits = Query(
            filter: #Predicate<Habit> { habit in
                habit.endDate == nil
            },
            sort: \Habit.startDate,
            order: .forward
        )
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(remainingTargetMetrics) { targetMetric in
                    SelectableHabitCell(targetMetric: targetMetric, isSelected: selectedTargetMetric == targetMetric)
                        .onTapGesture {
                            selectedTargetMetric = nil
                            selectedTargetMetric = targetMetric
                        }
                }
            }
            .navigationTitle("Create a Habit")
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
                    guard let metric = selectedTargetMetric, let value = proposedHabit?.value else { return }

                    let habit = Habit(
                        targetMetric: metric,
                        value: value,
                        unitString: metric.defaultUnit.unitString,
                        startDate: .now,
                        isSuggested: false,
                        isUserEdited: true
                    )
                    modelContext.insert(habit)

                    do {
                        try modelContext.save()
                    } catch {
                        self.error = error
                    }
                    dismiss()
                }
                .disabled(selectedTargetMetric == nil || (proposedHabit?.value ?? 0) < 1)
            }
            .alert(error: $error)
            .onChange(of: selectedTargetMetric, { _, newValue in
                guard let newValue else {
                    proposedHabit = nil
                    return
                }

                proposedHabit = ProposedGoal(
                    habitID: nil,
                    targetMetric: newValue,
                    value: 0,
                    suggestedValue: 0,
                    previousValue: nil,
                    unitString: newValue.defaultUnit.unitString,
                    vitalKind: nil,
                    context: nil,
                    hasUserEdited: true
                )
                showQuantitySheet = true
            })
            .sheet(isPresented: $showQuantitySheet) {
                ProposedHabitTargetValueEditCardView(proposedHabit: Binding(get: {
                    proposedHabit!
                }, set: { newValue in
                    proposedHabit = newValue
                }))
                .tint(selectedTargetMetric?.color ?? .mutedBlue)
            }
        }
    }
}

private extension UserAddedGoalPicker {

    var remainingTargetMetrics: [TargetMetric] {
        TargetMetric.allCases.filter({ targetMetric in
            if targetMetric == .none { return false }

            return !activeHabits.contains { habit in
                habit.targetMetric == targetMetric
            }
        })
    }
}

#Preview {
    UserAddedGoalPicker()
}
