//
//  ChildScoreValueView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct ChildScoreValueView: View {
    let title: String
    let score: Int

    init(_ title: String, score: Int) {
        self.title = title
        self.score = score
    }

    var body: some View {
        LabeledContent {
            Text("\(score)")
                .font(.title3)
                .foregroundStyle(foregroundColor)
                .fontDesign(.rounded)
                .bold()
        } label: {
            Text(title)
                .bold()
        }
    }
}

private extension ChildScoreValueView {

    var foregroundColor: Color {
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
    ChildScoreValueView(
        "Supplement Match to Goal Score",
        score: 6
    )
}
