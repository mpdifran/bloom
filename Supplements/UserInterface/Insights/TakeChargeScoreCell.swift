//
//  TakeChargeScoreCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct TakeChargeScoreCell: View {
    let score: TakeChargeScore

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Take Charge")
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
                "Exercise Score",
                score: score.exerciseScore
            )

            ChildScoreValueView(
                "vO2 Max Score",
                score: score.vo2maxScore
            )

            Divider()

            Text(score.shortText)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    List {
        TakeChargeScoreCell(
            score: .init(
                exerciseScore: 10,
                overallScore: 9,
                vo2maxScore: 8,
                shortText: "You are large and in charge and do what it takes."
            )
        )
    }
}
