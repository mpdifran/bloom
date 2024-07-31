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
            ScrollView {
                VStack {
                    ForEachEnumerated(viewModel.goals) { index, goal in
                        GoalCell(goal: goal, index: index)
                            .cardContainer()
                            .transition(.blurReplace)
                    }
                }
                .padding()
            }
            .navigationTitle("Goals")
            .background {
                Rectangle()
                    .fill(.background.secondary)
                    .ignoresSafeArea()
            }
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
