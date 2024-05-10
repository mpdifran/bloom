//
//  OverallScoreValueView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-10.
//

import SwiftUI

struct OverallScoreValueView: View {
    let score: Int

    var body: some View {
        Text("\(score)")
            .font(.title)
            .fontDesign(.rounded)
            .bold()
            .foregroundStyle(.white)
            .padding(10)
            .background {
                Circle()
                    .fill(backgroundColor)
            }
    }
}

private extension OverallScoreValueView {

    var backgroundColor: Color {
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
    VStack {
        OverallScoreValueView(score: 3)
        OverallScoreValueView(score: 6)
        OverallScoreValueView(score: 9)
    }
}
