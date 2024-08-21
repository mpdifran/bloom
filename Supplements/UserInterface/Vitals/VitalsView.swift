//
//  VitalsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-21.
//

import SwiftUI
import AppUI

struct VitalsView: View {

    @ObservedObject private var viewModel = VitalsViewModel.shared
    @ObservedObject private var goalsViewModel = GoalsViewModel.shared

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Text("Weekly Goals")
                        .bold()
                        .padding(.horizontal)
                        .zStackAlignment(.leading)

                    ForEachEnumeratedNoID(goalsViewModel.goals) { (index, goals) in
                        if let goal = goals.first {
                            GoalDailyUpdateCell(goal: goal)
                        }
                    }

                    Text("Vitals")
                        .bold()
                        .padding(.horizontal)
                        .zStackAlignment(.leading)
                        .padding(.top)

                    ForEach(viewModel.vitals) { vital in
                        NavigationLink(value: vital.id) {
                            MonthlyVitalCardCell(vital: vital)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .horizontallyCentered()
                .padding()
            }
            .navigationTitle("Vitals")
            .navigationDestination(for: VitalModel.Kind.self) { vitalKind in
                switch vitalKind {
                case .sleepQuality: SleepDetailsView()
                case .bodyComposition: BodyCompositionDetailsView()
                case .nutrition: NutritionDetailsView()
                case .stressLevels: StressDetailsView()
                case .activityLevel: ActivityLevelDetailsView()
                case .cardioFitness: CardioFitnessDetailsView()
                case .exerciseEffectiveness: ExerciseEffectivenessView()
                default: Text("Not Yet Implemented").navigationTitle(vitalKind.name)
                }
            }
            .animation(.default, value: viewModel.hrvStatus)
            .animation(.default, value: viewModel.sleepStatus)
            .animation(.default, value: viewModel.rhrStatus)
            .animation(.default, value: viewModel.vitals)
        }
        .tabItem {
            Label("Vitals", systemImage: "bolt.heart")
        }
        .onAppear {
            Task {
                await goalsViewModel.checkForUpdateGoals()
            }
        }
    }
}

#Preview {
    TabView {
        VitalsView()
    }
}
