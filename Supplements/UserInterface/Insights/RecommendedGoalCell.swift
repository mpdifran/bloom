//
//  RecommendedGoalCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-22.
//

import SwiftUI

struct RecommendedGoalCell: View {
    let goal: String

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    @ObservedObject private var profileViewModel = ProfileViewModel.shared

    var body: some View {
        HStack {
            Image(systemName: "flag.fill")
                .foregroundStyle(.tint)
            Text(goal)
                .font(.title3)
                .fontDesign(.rounded)
                .bold()
            Spacer()

            AddItemButton(hasAdded: userAddedGoal) {
                if userAddedGoal {
                    profileViewModel.userGoals.removeAll { $0 == goal }
                } else {
                    profileViewModel.userGoals.insert(goal, at: 0)
                }
            }
        }
        .animation(.bouncy, value: profileViewModel.userGoals.count)
        .onAppear {
            feedbackGenerator.prepare()
        }
    }
}

private extension RecommendedGoalCell {

    var userAddedGoal: Bool {
        profileViewModel.userGoals.contains(goal)
    }
}

#Preview {
    List {
        RecommendedGoalCell(goal: "Sleep better")
    }
}
