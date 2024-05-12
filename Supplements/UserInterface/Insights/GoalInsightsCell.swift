//
//  GoalInsightsCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct GoalInsightsCell: View {
    let goalInsights: GoalInsights

    var body: some View {
        VStack(alignment: .leading) {
            Text("Goal Insights")
                .multilineTextAlignment(.leading)
                .font(.title)
                .fontDesign(.rounded)
                .bold()

            Text(goalInsights.shortText)

            Divider()

            Text("Recommendations")
                .bold()

            Text(goalInsights.recommendedGoals.joined(separator: ", "))
        }
    }
}

#Preview {
    List {
        GoalInsightsCell(
            goalInsights: .init(
                recommendedGoals: [
                    "longevity",
                    "sleep",
                    "build muscle"
                ],
                shortText: "I love your current goals but I would suggest you also add sleep to your goals"
            )
        )
    }
}
