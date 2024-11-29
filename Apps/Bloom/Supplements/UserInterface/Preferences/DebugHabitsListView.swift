//
//  DebugHabitsListView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-20.
//

import SwiftUI
import SwiftData
import DataContainer

struct DebugHabitsListView: View {

    @Query(sort: \Habit.startDate, order: .reverse) var habits: [Habit]

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(habits) { habit in
                    DebugHabitCell(habit: habit)
                }
                .onDelete(perform: deleteHabits)
            }
            .navigationTitle("Debug Habits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private extension DebugHabitsListView {

    func deleteHabits(_ indexSet: IndexSet) {
        for index in indexSet {
            let habit = habits[index]
            modelContext.delete(habit)
            try? modelContext.save()
        }
    }
}

#Preview {
    NavigationStack {
        DebugHabitsListView()
    }
}
