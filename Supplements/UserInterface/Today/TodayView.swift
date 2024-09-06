//
//  TodayView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-01.
//

import SwiftUI
import AppUI

struct TodayView: View {

    @ObservedObject private var viewModel = TodayViewModel.shared
    @ObservedObject private var goalsViewModel = GoalsViewModel.shared

    @EnvironmentObject private var tabController: TabController

    @State private var presentedFullScreen: AnyView?
    @State private var presentedCardSheet: AnyView?

    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    TimelineView(.everyMinute) { context in
                        if Calendar.current.isMorning(date: .now) || danieleMode {
                            goodMorningCell
                        }
                    }

                    Text("Goals")
                        .bold()
                        .padding(.horizontal)
                        .zStackAlignment(.leading)

                    ForEachEnumeratedNoID(goalsViewModel.goals) { (index, goals) in
                        if let goal = goals.first {
                            NavigationLink {
                                GoalDetailsView(goals: $goalsViewModel.goals[index])
                            } label: {
                                GoalDailyUpdateCell(goal: goal)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("To Do")
                        .bold()
                        .padding(.horizontal)
                        .zStackAlignment(.leading)
                        .padding(.top)

                    ToDoActionCell(
                        title: "Weigh Yourself",
                        subtitle: "Daily",
                        systemImage: "gauge.with.dots.needle.bottom.50percent.badge.plus",
                        isComplete: viewModel.hasLoggedBodyWeight
                    )
                    .tint(.indigo)
                    .onTapGesture {
                        presentedCardSheet = BodyWeightActionCardView().asAny
                    }

                    ToDoActionCell(
                        title: "Drink Water",
                        subtitle: "500 mL / Day",
                        systemImage: "waterbottle.fill",
                        isComplete: viewModel.hasLoggedWater
                    )
                    .tint(.blue)
                    .onTapGesture {
                        presentedCardSheet = WaterActionCardView().asAny
                    }
                }
                .horizontallyCentered()
                .padding()
            }
            .navigationTitle("Today")
            .sheet($presentedCardSheet)
            .fullScreenCover($presentedFullScreen)
            .fullScreenCover(isPresented: $tabController.showMorningReport) {
                GoodMorningView()
            }
            .gradientRootBackground()
        }
        .tabItem {
            Label("Today", systemImage: "calendar.badge.checkmark")
        }
        .onAppear {
            viewModel.observeData()
            Task {
                await goalsViewModel.checkForUpdateGoals()
            }
        }
    }
}

private extension TodayView {

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
        .cardContainer()
        .contentShape(Rectangle())
        .onTapGesture {
            presentedFullScreen = GoodMorningView().asAny
        }
        .padding(.bottom)
    }
}

#Preview {
    TabView {
        TodayView()
    }
    .environmentObject(TabController())
}
