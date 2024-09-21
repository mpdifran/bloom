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
            List(habits) { habit in
                ForEach(habits) { habit in
                    HStack {
                        Text(habit.targetMetric.name)

                        Spacer()

                        Text(habit.displayQuantity)
                            .foregroundStyle(habit.targetMetric.color)
                            .bold()
                    }
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
        }
    }
}

#Preview {
    NavigationStack {
        DebugHabitsListView()
    }
}
