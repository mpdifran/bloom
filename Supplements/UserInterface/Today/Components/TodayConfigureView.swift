//
//  TodayConfigureView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-09.
//

import SwiftUI
import AppUI

struct TodayConfigureView: View {

    @ObservedObject private var goalsViewModel = GoalsViewModel.shared
    @ObservedObject private var toDoManager = ToDoManager.shared

    @State private var presentedSheet: AnyView?

    @Environment(\.dismiss) private var dismiss

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
    }
}

private extension TodayConfigureView {

    var habitsSection: some View {
        Section("Habits") {
            ForEach(goalsViewModel.habits) { (habit) in
                HabitCell(habit: habit)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    goalsViewModel.habits.remove(at: index)
                }
            }

            if goalsViewModel.notYetAddedHabits().isNotEmpty {
                Button {
                    presentedSheet = HabitGoalPicker { habit in
                        goalsViewModel.habits.append(habit)
                    }.asAny
                } label: {
                    Label("Add a Habit", systemImage: "plus")
                }
            }
        }
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
                    Label(todo.kind.name, systemImage: todo.kind.systemImage)
                        .foregroundStyle(todo.kind.color)
                        .bold()
                }
            }
        }
    }
}

#Preview {
    TodayConfigureView()
}
