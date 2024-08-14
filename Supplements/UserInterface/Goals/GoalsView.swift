//
//  GoalsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI
import SwiftData
import AppUI

@MainActor
struct GoalsView: View {

    @ObservedObject private var viewModel = GoalsViewModel.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    ForEachEnumeratedNoID(viewModel.goals) { index, _ in
                        GoalCell(goals: $viewModel.goals[index], index: index)
                            .cardContainer(fill: .background.secondary)
                            .transition(.blurReplace)
                    }
                }
                .padding()
                .horizontallyCentered()
            }
            .navigationTitle("Goals")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Force Refresh", systemImage: "arrow.triangle.2.circlepath") {
                        Task {
                            await viewModel.checkForUpdateGoals(force: true)
                        }
                    }
                }
            }
            .animation(.default, value: viewModel.goals)
        }
        .onAppear {
            Task {
                await viewModel.checkForUpdateGoals()
            }
        }
        .tabItem {
            Label("Goals", systemImage: "medal")
        }
    }
}

#Preview {
    TabView {
        GoalsView()
    }
}
