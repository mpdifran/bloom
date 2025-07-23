//
//  MorningReportInsightCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-23.
//

import SwiftUI

struct MorningReportInsightCell: View {
  let emoji: String
  let title: String
  let insight: String

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack(alignment: .top) {
        Text(title)
          .lineLimit(2)
        Spacer(minLength: 0)
        Text(emoji)
      }
      .font(.title2)
      .fontDesign(.rounded)
      .bold()
      .padding()
      .background {
        Rectangle()
          .fill(.background.secondary)
      }

      Text(insight)
        .font(.body)
        .fontDesign(.rounded)
        .padding()

      AskBudButton()
        .padding(.horizontal, 8)
        .padding(.bottom, 8)
        .horizontallyCentered()
    }
    .cardContainer(includePadding: false)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MorningReportInsightCell(
        emoji: "🍕",
        title: "Too Much Za",
        insight: "You had way too much pizza yesterday. Try to not do that today bro."
      )

      MorningReportInsightCell(
        emoji: "🤯",
        title: "New Running Workout Record",
        insight: "You ran 14 km in one go! Way to go buddy! You're making great progress towards your goal."
      )
    }
  }
}
