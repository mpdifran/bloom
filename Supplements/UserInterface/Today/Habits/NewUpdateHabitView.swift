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

    @State private var isLoading = true
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

                    if isLoading {
                        VStack(spacing: 20) {
                            CircularSpinnerView()
                                .foregroundStyle(.tint)
                            Text("Loading Focus Areas")
                                .font(.title2)
                                .bold()
                        }
                        .horizontallyCentered()
                        .padding(.top, 40)
                    } else {
                        if proposedHabits.isEmpty {
                            ContentUnavailableView(
                                "Oops",
                                systemImage: "exclamationmark.triangle.fill",
                                description: Text("There was a problem loading your focus areas. Please try again later.")
                            )
                        } else {
                            ForEachEnumerated(proposedHabits) { (index, proposedHabit) in
                                ProposedHabitCell(proposedHabit: $proposedHabits[index])
                                    .transition(.scale)
                            }
                        }
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
                    do {
                        try habitsViewModel.performSave(proposedHabits: proposedHabits)
                        dismiss()
                    } catch {
                        self.error = error
                    }
                }
            }
        }
        .tint(.mutedBlue)
        .alert(error: $error)
        .animation(.default, value: proposedHabits)
        .task {
            proposedHabits = await habitsViewModel.generateProposedHabits()
            isLoading = false
        }
    }
}

#Preview {
    NewUpdateHabitView()
}
