//
//  InsightsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI
import AppUI

struct InsightsView: View {

    @State private var presentedNavigationView: AnyView?
    @State private var error: Error?

    @ObservedObject private var viewModel = InsightsViewModel.shared
    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        NavigationStack {
            List {
                if let sleepAnalysis = healthManager.userInfo?.sleepAnalysis {
                    SleepScoreCell(sleepAnalysis: sleepAnalysis) {
                        presentedNavigationView = SleepSummaryView(sleepAnalysises: sleepAnalysis).asAny
                    }
                }

                WorkoutSummaryCell(workoutSummaries: viewModel.workoutSummary)

                TimeInDaylightCell(timeInDaylight: viewModel.timeInDaylight)

                RestingHeartRateCell(heartRateSamples: viewModel.restingHeartRate)

                MeditationMinutesCell(meditationMinutes: viewModel.meditationMinutes)
            }
            .navigationTitle("Insights")
            .navigationDestination($presentedNavigationView)
        }
        .animation(.default, value: healthManager.userInfo)
        .animation(.default, value: viewModel.workoutSummary.count)
        .onChange(of: healthManager.userInfo, { oldValue, newValue in
            guard newValue != nil else {
                return
            }
        })
        .task {
            do {
                try await viewModel.loadData()
            } catch {
                print(error)
            }
        }
        .tabItem {
            Label("Insights", systemImage: "heart.text.square")
        }
    }
}

private extension InsightsView {

    @ViewBuilder
    func content(response: InsightsResponse) -> some View {
        UserInfoInsightsSection(insights: response.userInfoInsights)

        Section {
            ForEach(response.activityRecommendations) { activity in
                ActivityCell(activityModel: activity)
            }
        } header: {
            Text("Activities")
                .multilineTextAlignment(.leading)
                .font(.title2)
                .fontDesign(.rounded)
                .bold()
                .textCase(.none)
        }

        if let insights = response.supplementInsights {
            SupplementInsightsSection(insights: insights)
        }
        if let insights = response.goalRecommendations {
            GoalInsightsSection(goalInsights: insights)
        }
    }
}

#Preview {
    TabView {
        InsightsView()
    }
}
