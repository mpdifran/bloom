//
//  InsightsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct InsightsView: View {

    @State private var isLoading = false
    @State private var error: Error?

    @ObservedObject private var viewModel = InsightsViewModel()
    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ContentUnavailableView("Loading Insights", systemImage: "heart.text.square")
                } else if let insightsResponse = viewModel.insights {
                    content(response: insightsResponse)
                } else {
                    ContentUnavailableView(label: {
                        Label("No Insights Available", systemImage: "heart.text.square")
                    }, actions: {
                        Button("Reload", systemImage: "arrow.counterclockwise") {
                            Task { await loadData() }
                        }
                        .buttonStyle(.borderedProminent)
                    })
                }
            }
            .navigationTitle("Insights")
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

    func content(response: InsightsResponse) -> some View {
        List {
            Section {
                GoalInsightsCell(goalInsights: response.goalsInsights)
            }
            Section {
                SupplementInsightsCell(insights: response.supplementInsights)
            }
            Section {
                NutrientsScoreCell(score: response.scores.nutrientsScore)
            }
            Section {
                RechargeScoreCell(score: response.scores.rechargeScore)
            }
            Section {
                TakeChargeScoreCell(score: response.scores.takeChargeScore)
            }
            Section {
                UserInfoInsightsCell(insights: response.userInfoInsights)
            }
        }
    }
}

private extension InsightsView {

    func loadData() async {
        guard viewModel.insights == nil else { return }

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
