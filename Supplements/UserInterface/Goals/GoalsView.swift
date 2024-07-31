//
//  GoalsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-31.
//

import SwiftUI
import SwiftData
import AppUI

struct GoalsView: View {

    @ObservedObject private var viewModel = GoalsViewModel.shared

    var body: some View {
        NavigationStack {
            List {
                ForEachEnumerated(viewModel.goals) { index, goal in
                    Section {
                        GoalCell(goal: goal, index: index)
                    }
                }
            }
            .navigationTitle("Goals")
        }
        .onAppear {
            viewModel.checkForUpdateGoals()
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
