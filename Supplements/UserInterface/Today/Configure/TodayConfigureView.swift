//
//  TodayConfigureView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-09.
//

import SwiftUI
import AppUI
import SwiftData
import DataContainer

struct TodayConfigureView: View {

    @ObservedObject private var toDoManager = ToDoManager.shared

    @State private var presentedSheet: AnyView?
    @State private var error: Error?

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var userAddedHabits: [Habit]
    @Query private var allHabits: [Habit]

    init() {
        _userAddedHabits = Query(
            filter: #Predicate<Habit> { habit in
                habit.endDate == nil && !habit.isSuggested
            },
            sort: \Habit.startDate,
            order: .forward
        )
    }

    var body: some View {
        NavigationStack {
            List {
                habitsSection
                toDoSection
            }
            .navigationTitle("Configure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .bold()
                }
            }
        }
        .sheet($presentedSheet)
        .alert(error: $error)
    }
}

private extension TodayConfigureView {

    var habitsSection: some View {
        Section("Habits") {
            ForEach(userAddedHabits) { (habit) in
                UserAddedHabitCell(habit: habit)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let habit = userAddedHabits[index]
                    habit.endDate = .now
                }
                do {
                    try modelContext.save()
                } catch {
                    self.error = error
                }
            }

            if remainingMetrics.isNotEmpty {
                Button {
                    presentedSheet = UserAddedGoalPicker().asAny
                } label: {
                    Label("Add a Habit", systemImage: "plus")
                }
            }
        }
    }

    var remainingMetrics: [TargetMetric] {
        TargetMetric.allCases.filter({ targetMetric in
            !allHabits.contains(where: { habit in
                habit.targetMetric == targetMetric
            })
        })
    }

    var toDoSection: some View {
        Section("To Dos") {
            ForEachEnumerated(toDoManager.allToDos) { (index, todo) in
                Picker(selection: $toDoManager.allToDos[index].cadence) {
                    ForEach(ToDoModel.Cadence.allCases) { cadence in
                        Text(cadence.name)
                            .tag(cadence)
                    }
                } label: {
                    Text(todo.kind.name)
                }
            }
        }
    }
}

#Preview {
    TodayConfigureView()
}
