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

    @EnvironmentObject private var tabContorller: TabController

    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

    @State private var path = NavigationPath()
    @State private var presentedFullScreen: AnyView?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    TimelineView(.everyMinute) { context in
                        if Calendar.current.isMorning(date: .now) || danieleMode {
                            goodMorningCell
                        }
                    }

                    Text("Today's Goals")
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
            .navigationTitle("For You")
            .navigationDestination(for: VitalModel.Kind.self) { vitalKind in
                switch vitalKind {
                case .sleepQuality: SleepDetailsView()
                case .bodyComposition: BodyCompositionDetailsView()
                case .nutrition: NutritionDetailsView()
                case .stressLevels: StressDetailsView()
                case .activityLevel: ActivityLevelDetailsView()
                case .cardioFitness: CardioFitnessDetailsView()
                case .exerciseEffectiveness: ExerciseEffectivenessView()
//                default: Text("Not Yet Implemented").navigationTitle(vitalKind.name)
                }
            }
            .fullScreenCover($presentedFullScreen)
            .fullScreenCover(isPresented: $tabContorller.showMorningReport) {
                GoodMorningView()
            }
            .animation(.default, value: viewModel.hrvStatus)
            .animation(.default, value: viewModel.sleepStatus)
            .animation(.default, value: viewModel.rhrStatus)
            .animation(.default, value: viewModel.vitals)
        }
        .tabItem {
            Label("For You", systemImage: "bolt.heart")
        }
        .onAppear {
            Task {
                await goalsViewModel.checkForUpdateGoals()
            }
        }
    }
}

private extension VitalsView {

    @ViewBuilder
    var goodMorningCell: some View {
        HStack {
            Image(systemName: "sunrise")
                .foregroundStyle(.orange)
                .font(.title2)

            VStack(alignment: .leading) {
                Text("Morning Report")
                    .font(.title3)
                    .bold()
                Text("Everything you need to start your day.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.forward")
                .foregroundStyle(.secondary)
        }
        .cardContainer(fill: .background.secondary)
        .contentShape(Rectangle())
        .onTapGesture {
            presentedFullScreen = GoodMorningView().asAny
        }
        .padding(.bottom)
    }
}

#Preview {
    TabView {
        VitalsView()
    }
}
