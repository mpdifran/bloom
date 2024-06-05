//
//  UserInfoInsightsSection.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct UserInfoInsightsSection: View {
    let insights: [UserInfoInsight]

    var body: some View {
        Section {
            ForEach(sortedInsights, id: \.name) { insight in
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: insight.importanceSystemImageName)
                            .foregroundStyle(.white, insight.importanceColor)
                            .bold()
                            .font(.largeTitle)

                        Spacer()

                        MetricView(value: insight.currentValue, unit: insight.units)

                        Image(systemName: "arrow.right")
                            .font(.title3)
                            .bold()
                            .fontDesign(.rounded)
                            .foregroundStyle(.tint)

                        MetricView(value: insight.goalValue, unit: insight.units)

                    }
                    
                    Text(insight.name)
                        .bold()

                    Text(insight.shortText)
                }

            }
        } header: {
            Text("Health Data Insights")
                .multilineTextAlignment(.leading)
                .font(.title2)
                .fontDesign(.rounded)
                .bold()
                .textCase(.none)
        }
    }
}

extension UserInfoInsightsSection {

    var sortedInsights: [UserInfoInsight] {
        insights.sorted(by: { $0.importance > $1.importance })
    }
}

private struct MetricView: View {
    let value: Double
    let unit: String

    var body: some View {
        VStack(spacing: 0) {
            Text("\(value, specifier: "%.0f")")
                .font(.title2)
                .bold()
                .fontDesign(.rounded)
            Text(unit)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    List {
        UserInfoInsightsSection(
            insights: [
                .init(
                    name: "Nightly Sleep Hours",
                    range: .below,
                    currentValue: 2.5,
                    goalValue: 3,
                    units: "hours",
                    shortText: "For adults it's recommended to sleep between 7-9 hours per night",
                    importance: 5
                ),
                .init(
                    name: "Daily Exercise Minutes",
                    range: .above,
                    currentValue: 400,
                    goalValue: 60,
                    units: "minutes",
                    shortText: "You're exercising too much! Try and reduce your daily average exercise minutes to give your body time to recover.",
                    importance: 3
                )
            ]
        )
    }
}
