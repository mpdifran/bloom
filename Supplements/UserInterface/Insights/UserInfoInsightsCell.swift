//
//  UserInfoInsightsCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct UserInfoInsightsCell: View {
    let insights: [UserInfoInsight]

    var body: some View {
        VStack(alignment: .leading) {
            Text("Health Data Insights")
                .multilineTextAlignment(.leading)
                .font(.title)
                .fontDesign(.rounded)
                .bold()

            ForEach(sortedInsights, id: \.metricName) { insight in
                Divider()
                HStack(alignment: .top) {
                    Text("\(insight.importance)")
                        .font(.title2)
                        .fontDesign(.rounded)
                        .bold()
                        .foregroundStyle(.tint)

                    Text(insight.shortText)
                }
            }
        }
    }
}

extension UserInfoInsightsCell {

    var sortedInsights: [UserInfoInsight] {
        insights.sorted(by: { $0.importance > $1.importance })
    }
}

#Preview {
    List {
        UserInfoInsightsCell(
            insights: [
                .init(
                    importance: 5,
                    inRange: 0,
                    metricName: "daily_sleep_hours",
                    shortText: "For adults it's recommended to sleep between 7-9 hours per night"
                ),
                .init(
                    importance: 4,
                    inRange: 1,
                    metricName: "daily_exercise_minutes",
                    shortText: "Adults should exercise at least 20 minutes per day on average, your exercise period is fine"
                )
            ]
        )
    }
}
