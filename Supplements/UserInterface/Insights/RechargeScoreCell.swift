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

                OverallScoreValueView(score: score.overallScore ?? 0)
            }
            .font(.title)
            .fontDesign(.rounded)
            .bold()

            Divider()

            ChildScoreValueView(
                "HRV Score",
                score: score.hrvScore ?? 0
            )

            ChildScoreValueView(
                "Meditation Score",
                score: score.meditationScore ?? 0
            )

            ChildScoreValueView(
                "Sleep Score",
                score: score.sleepScore ?? 0
            )
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
                sleepScore: 10
            )
        )
    }
}
