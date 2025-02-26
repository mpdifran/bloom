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
      Image(systemName: "sparkles")
        .foregroundStyle(
          LinearGradient(
            colors: [.mutedTeal, .mutedBlue, .mutedIndigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .font(.title)
        .frame(width: 40)

      VStack(alignment: .leading) {
        Text("Review Goals")
          .font(.title3)
          .bold()
          .fontDesign(.rounded)
        Text("Review your goals and make adjustments.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      DisclosureIndicator()
    }
    .cardContainer()
  }
}

#Preview {
  ScrollView {
    VStack {
      GoalReviewCell()
    }
    .horizontallyCentered()
    .padding()
  }
  .groupedBackground()
}
