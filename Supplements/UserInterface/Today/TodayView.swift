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

    @EnvironmentObject private var tabContorller: TabController

    @State private var presentedFullScreen: AnyView?

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
                            GoalDailyUpdateCell(goal: goal)
                        }
                    }
                }
                .horizontallyCentered()
                .padding()
            }
            .navigationTitle("Today")
            .fullScreenCover($presentedFullScreen)
            .fullScreenCover(isPresented: $tabContorller.showMorningReport) {
                GoodMorningView()
            }
        }
        .tabItem {
            Label("Today", systemImage: "calendar.badge.checkmark")
        }
        .onAppear {
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
        TodayView()
    }
}
