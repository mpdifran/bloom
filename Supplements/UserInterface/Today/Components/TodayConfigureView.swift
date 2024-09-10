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

    @State private var presentedSheet: AnyView?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
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

#Preview {
    TodayConfigureView()
}
