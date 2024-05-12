//
//  RechargeScoreCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct RechargeScoreCell: View {
    let score: RechargeScore

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Recharge")
                    .multilineTextAlignment(.leading)
                    .font(.title)
                    .fontDesign(.rounded)
                    .bold()

                Spacer()

                OverallScoreValueView(score: score.overallScore)
            }
            .font(.title)
            .fontDesign(.rounded)
            .bold()

            Divider()

            ChildScoreValueView(
                "HRV Score",
                score: score.hrvScore
            )

            ChildScoreValueView(
                "Meditation Score",
                score: score.meditationScore
            )

            ChildScoreValueView(
                "Sleep Score",
                score: score.sleepScore
            )

            Divider()

            Text(score.shortText)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    List {
        RechargeScoreCell(
            score: .init(
                hrvScore: 8,
                meditationScore: 10,
                overallScore: 9,
                sleepScore: 10,
                shortText: "You are kind to yourself and sleep enough"
            )
        )
    }
}
