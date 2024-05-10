//
//  NutrientsScoreCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct NutrientsScoreCell: View {
    let score: NutrientsScore

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Nutrients")
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
                "Supplement Goal Score",
                score: score.supplementMatchToGoalScore
            )

            ChildScoreValueView(
                "Supplement Scientific Score",
                score: score.supplementScientificScore
            )

            Divider()

            Text(score.shortText)
                .multilineTextAlignment(.leading)
        }
    }
}



#Preview {
    List {
        NutrientsScoreCell(
            score: .init(
                overallScore: 8,
                supplementMatchToGoalScore: 6,
                supplementScientificScore: 10,
                shortText: "You are supplementing the amazing machine that is your body with the right stuff. But your supplements do not match your current goals."
            )
        )
    }
}
