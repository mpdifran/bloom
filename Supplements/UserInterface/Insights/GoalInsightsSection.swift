//
//  GoalInsightsSection.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct GoalInsightsSection: View {
    let goalInsights: GoalInsights

    var body: some View {
        Section {
            Text(goalInsights.shortText)

            ForEach(goalInsights.recommendedGoals, id: \.self) { goal in
                RecommendedGoalCell(goal: goal)
            }
        } header: {
            Text("Recommended Goals")
                .multilineTextAlignment(.leading)
                .font(.title2)
                .fontDesign(.rounded)
                .bold()
                .textCase(.none)
        }
    }
}

#Preview {
    List {
        GoalInsightsSection(
            goalInsights: .init(
                shortText: "I love your current goals but I would suggest you also add sleep to your goals.",
                recommendedGoals: [
                    "Longevity",
                    "Sleep",
                    "Build muscle"
                ]
            )
        )
    }
}
