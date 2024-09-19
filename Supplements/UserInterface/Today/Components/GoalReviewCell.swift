//
//  GoalReviewCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-19.
//

import SwiftUI

struct GoalReviewCell: View {

    var body: some View {
        HStack {
            Image(systemName: "trophy.fill")
                .foregroundStyle(.mutedOrange)
                .font(.title2)

            VStack(alignment: .leading) {
                Text("Review Focus Areas")
                    .bold()
            }

            Spacer()
        }
        .cardContainer(
            fill: .mutedOrange.opacity(0.3),
            stroke: .mutedOrange
        )
    }
}

#Preview {
    ScrollView {
        VStack {
            GoalReviewCell()
        }
        .zStackAlignment(.center)
        .padding()
    }
    .gradientRootBackground()
}
