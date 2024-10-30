//
//  OnboardingFocusAreasView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI
import AppUI
import DataContainer
import TelemetryDeck

struct OnboardingFocusAreasView: View {
    let onContinue: () -> Void

    @State private var index = 1

    @State private var vitals = [VitalModel]()

    @State private var showContinue = false
    @State private var didContinue = false
    @State private var vitalKinds = [VitalModel.Kind]()
    @State private var proposedFocusAreas = [ProposedHabit]()
    @State private var proposedHabits = [ProposedHabit]()
    @State private var proposedToDos = [ProposedToDo]()
    @State private var error: Error?

    private let vitalsViewModel = VitalsViewModel.shared



    @ObservedObject private var habitsViewModel = HabitsViewModel.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Great! Let's determine which parts of your health we should focus on.")
                    .onboardingTextStyle()
                    .appear(with: 1, currentIndex: index)


                if vitals.isEmpty {
                    CircularSpinnerView()
                        .foregroundStyle(.tint)
                        .horizontallyCentered()
                } else {
                    Group {
                        ForEach(vitals) { vital in
                            MiniVitalCell(vital: vital)
                                .transition(.scale)
                        }
                    }
                }

                Text("Now let's calculate some goals to tackle these based on your Health data.")
                    .onboardingTextStyle()
                    .appear(with: 3, currentIndex: index)

                VStack {
                    if proposedFocusAreas.isNotEmpty {
                        SectionTitleView("Focus Areas")
                            .padding(.horizontal)

                        ForEachEnumerated(proposedFocusAreas) { (index, _) in
                            ProposedHabitCell(
                                proposedHabit: $proposedFocusAreas[index],
                                includeActions: true
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
                                includeActions: true
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
                .appear(with: 4, currentIndex: index)
            }
            .horizontalAlignment(.leading)
            .padding()
        }
        .if(showContinue) {
            $0.shelf {
                Button("Continue") {
                    do {
                        try habitsViewModel.performSave(
                            proposedFocusAreas: proposedFocusAreas,
                            proposedHabits: proposedHabits,
                            proposedToDos: proposedToDos
                        )
                        didContinue.toggle()
                        onContinue()
                    } catch {
                        self.error = error
                    }
                }
                .buttonStyle(.onboarding)
            }
        }
        .animation(.bouncy, value: vitals.count)
        .animation(.default, value: index)
        .sensoryFeedback(.selection, trigger: index)
        .sensoryFeedback(.selection, trigger: didContinue)
        .onChange(of: vitalKinds) { _, _ in
            loadVitals()
        }
        .onChange(of: index) { _, _ in
            loadVitals()
        }
        .topSafeAreaBlur()
        .task {
            while index < 4 {
                await advanceIndex()
            }

            await Delay(1700)

            showContinue = true
        }
        .alert(error: $error)
        .task {
            let result = await habitsViewModel.generateProposedHabits()

            vitalKinds = result.allVitalKinds

            proposedFocusAreas = result.proposedFocusAreas
            proposedHabits = result.proposedHabits
            proposedToDos = result.proposedToDos
        }
        .onAppear {
            TelemetryDeck.signal("OB Focus Areas")
        }
    }
}

private extension OnboardingFocusAreasView {

    func advanceIndex() async {
        await Delay(1700)

        index += 1
    }

    func loadVitals() {
        guard index >= 2 && vitalKinds.isNotEmpty && vitals.isEmpty else { return }

        vitals = vitalsViewModel.allVitals.filter({ vitalKinds.contains($0.id) })
    }
}

#Preview {
    OnboardingFocusAreasView { }
}
