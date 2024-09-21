//
//  NewUpdateHabitView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-20.
//

import SwiftUI
import AppUI
import DataContainer

struct NewUpdateHabitView: View {

    @ObservedObject private var habitsViewModel = HabitsViewModel.shared

    @State private var proposedHabits = [ProposedHabit]()
    @State private var error: Error?

    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Let's Start the Week Right!")
                                .font(.title2)
                                .bold()

                            Text("Review your goals for the week. These recommendations are based off the data from the past two weeks.")
                        }

                        Spacer(minLength: 0)
                    }
                    .cardContainer()

                    ForEachEnumerated(proposedHabits) { (index, proposedHabit) in
                        ProposedHabitCell(proposedHabit: $proposedHabits[index])
                    }
                }
                .horizontallyCentered()
                .padding()
            }
            .groupedBackground()
            .navigationTitle("Focus Areas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .bold()
                }
            }
            .shelf {
                ProminentButton("Save") {
                    performSave()
                    dismiss()
                }
            }
        }
        .tint(.mutedBlue)
        .alert(error: $error)
        .task {
            proposedHabits = await habitsViewModel.generateProposedHabits()
        }
    }
}

private extension NewUpdateHabitView {

    func performSave() {
        for proposedHabit in proposedHabits {
            let habit = Habit(
                targetMetric: proposedHabit.targetMetric,
                value: proposedHabit.value,
                unitString: proposedHabit.unitString,
                startDate: .now,
                isSuggested: true,
                isUserEdited: false,
                vitalKind: proposedHabit.vitalKind,
                context: proposedHabit.context
            )

            modelContext.insert(habit)
        }

        do {
            try modelContext.save()
        } catch {
            self.error = error
        }
    }
}

#Preview {
    NewUpdateHabitView()
}
