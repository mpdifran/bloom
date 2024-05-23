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

                OverallScoreValueView(score: score.overallScore ?? 0)
            }
            .font(.title)
            .fontDesign(.rounded)
            .bold()

            Divider()

            ChildScoreValueView(
                "Supplement Goal Score",
                score: score.supplementMatchToGoalScore ?? 0
            )

            ChildScoreValueView(
                "Supplement Scientific Score",
                score: score.supplementScientificScore ?? 0
            )
        }
    }
}



#Preview {
    List {
        NutrientsScoreCell(
            score: .init(
                overallScore: 8,
                supplementMatchToGoalScore: 6,
                supplementScientificScore: 10
            )
        )
    }
}
