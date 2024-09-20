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
                .overlay {
                    ZStack {
                        Circle()
                            .fill(.mutedRed)
                            .frame(square: 10)
                            .zStackAlignment(.topTrailing)
                    }
                }

            VStack(alignment: .leading) {
                Text("Review Focus Areas")
                    .bold()
                    .foregroundStyle(.tint)
            }

            Spacer()
        }
        .cardContainer(
            fill: .tint.opacity(0.3),
            stroke: .tint
        )
        .tint(.mutedBlue)
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
