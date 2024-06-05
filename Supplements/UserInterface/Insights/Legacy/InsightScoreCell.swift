//
//  InsightScoreCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-23.
//

import SwiftUI

extension InsightScoreCell {
    struct ChildScore: Identifiable {
        var id: String { name }
        let name: String
        let score: Int
    }
}

struct InsightScoreCell: View {
    let title: String
    let overallScore: Int
    let childScores: [ChildScore]

    var body: some View {
        VStack {
            VStack {
                Text("\(overallScore)")
                    .font(.system(size: 80))
                    .fontDesign(.rounded)
                    .bold()
                    .foregroundStyle(color(for: overallScore))

                Text(title)
                    .font(.title)
                    .bold()
            }

            Divider()

            ForEach(childScores) { childScore in
                HStack {
                    Text(childScore.name)
                        .bold()

                    Spacer()

                    Text("\(childScore.score)")
                        .font(.largeTitle)
                        .bold()
                        .fontDesign(.rounded)
                        .foregroundStyle(color(for: childScore.score))
                }
            }
        }
    }
}

private extension InsightScoreCell {

    func color(for score: Int) -> Color {
        switch score {
        case 0, 1, 2, 3:
            return .red
        case 4, 5, 6, 7:
            return .orange
        default:
            return .green
        }
    }
}

#Preview {
    List {
        InsightScoreCell(
            title: "Recharge Score",
            overallScore: 9,
            childScores: [
                .init(name: "Sleep Score", score: 3),
                .init(name: "HRV Score", score: 7)
            ]
        )
    }
}
