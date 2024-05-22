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
                    ContentUnavailableView {
                        Label {
                            Text("Loading Insights")
                        } icon: {
                            Image(systemName: "heart.text.square")
                                .foregroundStyle(.tint)
                        }
                    }
                } else if let insightsResponse = viewModel.insights {
                    content(response: insightsResponse)
                } else {
                    ContentUnavailableView(label: {
                        Label {
                            Text("No Insights Available")
                        } icon: {
                            Image(systemName: "heart.text.square")
                                .foregroundStyle(.tint)
                        }
                    }, actions: {
                        Button("Reload", systemImage: "arrow.counterclockwise") {
                            Task { await loadData() }
                        }
                        .padding()
                        .buttonStyle(.borderedProminent)
                    })
                }
            }
            .navigationTitle("Insights")
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

    func content(response: InsightsResponse) -> some View {
        List {
            UserInfoInsightsSection(insights: response.userInfoInsights)

            if let insights = response.supplementInsights {
                SupplementInsightsSection(insights: insights)
            }
            if let insights = response.goalsInsights {
                GoalInsightsSection(goalInsights: insights)
            }
        }
    }
}

private extension InsightsView {

    func loadData(force: Bool = false) async {
        guard !force && viewModel.insights == nil else { return }

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
