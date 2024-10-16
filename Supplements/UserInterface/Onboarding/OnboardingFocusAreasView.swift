//
//  OnboardingFocusAreasView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI
import AppUI

struct OnboardingFocusAreasView: View {
    let onContinue: () -> Void

    @State private var isCalculatingGoals = true
    @State private var showContinue = false
    @State private var proposedFocusAreas = [ProposedHabit]()
    @State private var proposedHabits = [ProposedHabit]()
    @State private var proposedToDos = [ProposedToDo]()
    @State private var error: Error?

    @ObservedObject private var habitsViewModel = HabitsViewModel.shared

    var body: some View {
        OnboardingCardTemplateView(aspectRatio: 1.3) {
            OnboardingTitleCardView(
                systemImage: "trophy.circle.fill",
                title: "Focus Areas",
                message: "Bloom will identify the best way to improve your health."
            )

        } bottom: {
            if isCalculatingGoals {
                VStack(spacing: 20) {
                    Spacer()
                    CircularSpinnerView()
                        .foregroundStyle(.tint)
                    Text("Calculating...")
                        .bold()
                    Spacer()
                }
                .horizontallyCentered()
            } else {
                ScrollView {
                    VStack {
                        if proposedFocusAreas.isNotEmpty {
                            SectionTitleView("Focus Areas")
                                .padding(.horizontal)

                            ForEachEnumerated(proposedFocusAreas) { (index, _) in
                                ProposedHabitCell(
                                    proposedHabit: $proposedFocusAreas[index],
                                    includeActions: false
                                )
                                .transition(.scale)
                            }
                        }

                        if proposedHabits.isNotEmpty {
                            SectionTitleView("New Habits")
                                .padding(.horizontal)

                            ForEachEnumerated(proposedHabits) { (index, _) in
                                ProposedHabitCell(
                                    proposedHabit: $proposedHabits[index],
                                    includeActions: false
                                )
                                .transition(.scale)
                            }
                        }

                        if proposedToDos.isNotEmpty {
                            SectionTitleView("To Do")
                                .padding(.horizontal)

                            ForEach(proposedToDos) { proposedToDo in
                                ProposedToDoCell(proposedToDo: proposedToDo)
                                    .transition(.scale)
                            }
                        }
                    }
                    .padding()
                }
                .scrollIndicators(.hidden)
            }
        }
        .if(showContinue) {
            $0.shelf {
                ProminentButton("Continue") {
                    do {
                        try habitsViewModel.performSave(
                            proposedFocusAreas: proposedFocusAreas,
                            proposedHabits: proposedHabits,
                            proposedToDos: proposedToDos
                        )
                        onContinue()
                    } catch {
                        self.error = error
                    }
                }
            }
        }
        .animation(.easeIn(duration: 1), value: isCalculatingGoals)
        .alert(error: $error)
        .tint(.mutedOrange)
        .task {
            let result = await habitsViewModel.generateProposedHabits()
            await MainActor.run {
                proposedFocusAreas = result.proposedFocusAreas
                proposedHabits = result.proposedHabits
                proposedToDos = result.proposedToDos
            }

            await Delay(1000)

            await MainActor.run {
                isCalculatingGoals = false
            }

            await Delay(2000)

            await MainActor.run {
                showContinue = true
            }
        }
    }
}

#Preview {
    OnboardingFocusAreasView { }
}
