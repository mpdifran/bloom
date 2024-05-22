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

            Button(action: {
                guard !userAddedGoal else { return }

                profileViewModel.userGoals.insert(goal, at: 0)
                feedbackGenerator.impactOccurred()
            }, label: {
                Image(systemName: userAddedGoal ? "checkmark.circle.fill" : "plus.circle.fill")
                    .foregroundStyle(.white, .tint)
                    .font(.largeTitle)
                    .fontDesign(.rounded)
                    .contentTransition(.symbolEffect)
            })
        }
        .animation(.bouncy, value: profileViewModel.userGoals.count)
        .onAppear {
            feedbackGenerator.prepare()
        }
    }
}

private extension RecommendedGoalCell {

    var userAddedGoal: Bool {
        profileViewModel.userGoals.contains { userGoal in
            userGoal.localizedCaseInsensitiveContains(goal) ||
            goal.localizedCaseInsensitiveContains(userGoal)
        }
    }
}

#Preview {
    List {
        RecommendedGoalCell(goal: "Sleep better")
    }
}
