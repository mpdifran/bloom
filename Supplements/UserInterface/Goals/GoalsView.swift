//
//  GoalsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

struct GoalsView: View {

    @ObservedObject private var viewModel = GoalViewModel.shared

    @State private var isLoading = false
    @State private var error: Error?

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ContentUnavailableView("Loading Goals", systemImage: "flag")
                } else if viewModel.goals.isEmpty {
                    ContentUnavailableView(label: {
                        Label("Failed to Load Goals", systemImage: "flag")
                    }, actions: {
                        Button("Reload", systemImage: "arrow.counterclockwise") {
                            Task {
                                await loadData()
                            }
                        }
                    })
                } else {
                    ScrollView {
                        ForEach(viewModel.goals) { goal in
                            GoalCell(
                                goal: goal,
                                isSelected: viewModel.isGoalSelected(goal)
                            )
                            .onTapGesture {
                                viewModel.toggleSelect(goal: goal)
                                feedbackGenerator.impactOccurred()
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Goals")
        }
        .tabItem {
            Label("Goals", systemImage: "flag")
        }
        .onAppear {
            feedbackGenerator.prepare()
        }
        .alert(error: $error)
        .task { await loadData() }
    }
}

private extension GoalsView {

    func loadData() async {
        guard viewModel.goals.isEmpty else { return }

        await MainActor.run { isLoading = true }
        do {
            try await viewModel.loadGoals()
        } catch {
            self.error = error
        }
        await MainActor.run { isLoading = false }
    }
}

#Preview {
    GoalsView()
}
