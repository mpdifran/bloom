//
//  InsightsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI
import AppUI

struct InsightsView: View {

    @State private var isLoading = false
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

                if isLoading {
                    Section {
                        VStack {
                            ProgressView()
                            Text("Loading Insights")
                                .bold()
                        }
                        .zStackAlignment(.center)
                    }
                } else if let insightsResponse = viewModel.insights {
                    content(response: insightsResponse)
                } else {
                    HStack {
                        Spacer()
                        Button("Reload Insights", systemImage: "arrow.clockwise") {
                            Task { await loadData(force: true) }
                        }
                        Spacer()
                    }
                }
            }
            .navigationTitle("Insights")
            .navigationDestination($presentedNavigationView)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Reload", systemImage: "arrow.clockwise") {
                        Task {
                            await loadData(force: true)
                        }
                    }
                }
            }
        }
        .onChange(of: healthManager.userInfo, { oldValue, newValue in
            guard newValue != nil else {
                return
            }

            Task {
                await loadData()
            }
        })
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

private extension InsightsView {

    func loadData(force: Bool = false) async {
        guard force || viewModel.insights == nil else { return }

        await MainActor.run { isLoading = true }
        do {
            try await viewModel.loadData()
        } catch {
            print(error)
            self.error = error
        }
        await MainActor.run { isLoading = false }
    }
}

#Preview {
    TabView {
        InsightsView()
    }
}
