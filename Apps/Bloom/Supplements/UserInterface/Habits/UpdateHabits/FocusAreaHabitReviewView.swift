//
//  FocusAreaHabitReviewView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-05.
//

import SwiftUI
import DataContainer
import AppUI

struct FocusAreaHabitReviewView: View {
    let vitals: [VitalModel]
    let onContinue: () -> Void

    @State private var index = 1
    @State private var isLoading = true
    @State private var newHabits = NewHabitResult()
    @State private var error: Error?

    @ObservedObject private var habitsViewModel = HabitsViewModel.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Great! Let's see what we can do to improve these Vitals.")
                    .transition(.opacity)
                    .appear(with: 1, currentIndex: index)
                    .onboardingTextStyle()

                Group {
                    if isLoading {
                        loadingView
                    } else {
                        contentView
                    }
                }
                .appear(with: 2, currentIndex: index, secondaryIfNotCurrentIndex: false)
            }
            .horizontalAlignment(.leading)
            .padding()
        }
        .shelf {
            ProminentButton("Let's Do It!") {
                do {
                    try habitsViewModel.performSave(
                        proposedFocusAreas: newHabits.proposedFocusAreas,
                        proposedHabits: newHabits.proposedHabits,
                        proposedToDos: newHabits.proposedToDos
                    )
                    onContinue()
                } catch {
                    self.error = error
                }
            }
            .foregroundStyle(.invertedText)
            .transition(.move(edge: .bottom))
            .appear(with: 3, currentIndex: index)
        }
        .sensoryFeedback(.selection, trigger: index)
        .sensoryFeedback(.success, trigger: isLoading)
        .animation(.default, value: index)
        .animation(.bouncy, value: isLoading)
        .alert(error: $error)
        .task {
            while index < 2 {
                await advanceIndex()
            }
            await loadHabits()
            await advanceIndex()
        }
    }
}

private extension FocusAreaHabitReviewView {

    @ViewBuilder
    var contentView: some View {
        if newHabits.proposedFocusAreas.isNotEmpty {
            SectionTitleView("Focus Areas")
                .padding(.horizontal)

            ForEachEnumerated(newHabits.proposedFocusAreas) { (index, _) in
                ProposedHabitCell(proposedHabit: $newHabits.proposedFocusAreas[index])
                    .transition(.scale)
            }
        }

        if newHabits.proposedHabits.isNotEmpty {
            SectionTitleView("New Habits")
                .padding(.horizontal)

            ForEachEnumerated(newHabits.proposedHabits) { (index, _) in
                ProposedHabitCell(proposedHabit: $newHabits.proposedHabits[index])
                    .transition(.scale)
            }
        }

        if newHabits.proposedToDos.isNotEmpty {
            SectionTitleView("To Do")
                .padding(.horizontal)

            ForEach(newHabits.proposedToDos) { proposedToDo in
                ProposedToDoCell(proposedToDo: proposedToDo)
                    .transition(.scale)
            }
        }
    }

    var loadingView: some View {
        VStack(spacing: 20) {
            CircularSpinnerView()
                .foregroundStyle(.tint)
            Text("Loading Focus Areas")
                .font(.title2)
                .bold()
        }
        .horizontallyCentered()
        .padding(.top, 40)
    }
}

private extension FocusAreaHabitReviewView {

    func advanceIndex() async {
        await Delay(1000)

        index += 1
    }

    func loadHabits() async {
        newHabits = await HabitsFactory.shared.generateProposedHabits(vitals: vitals)
        isLoading = false
    }
}

#Preview {
    FocusAreaHabitReviewView(
        vitals: [
            VitalModel(
                id: .nutrition,
                subtitle: nil,
                status: nil,
                color: nil,
                barLevel: nil,
                hasNoData: false
            ),
            VitalModel(
                id: .stressLevels,
                subtitle: nil,
                status: nil,
                color: nil,
                barLevel: nil,
                hasNoData: false
            )
        ]
    ) { }
}
