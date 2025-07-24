//
//  MorningReportReadinessCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-07-24.
//

import SwiftUI

struct MorningReportReadinessCell: View {
  let readinessScore: Int
  let summary: String

  var body: some View {
    HStack(alignment: .top) {
      Text("\(readinessScore)")
        .font(.system(size: 70))
        .monospacedDigit()
        .fontDesign(.rounded)
        .fontWeight(.heavy)
        .foregroundStyle(
          LinearGradient(
            colors: [.mutedOrange, .mutedPink, .mutedPurple, .mutedIndigo],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
          )
        )
        .padding(.horizontal, 20)
        .background {
          Circle()
            .fill(.background.secondary)
        }

      VStack(alignment: .leading) {
        Text("Readiness Score")
          .font(.headline)
          .fontDesign(.rounded)
          .bold()
        Text(summary)
          .font(.body)
          .fixedSize(horizontal: false, vertical: true)
        Spacer(minLength: 0)
      }
      .multilineTextAlignment(.leading)

      Spacer(minLength: 0)
    }
    .cardContainer()
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      MorningReportReadinessCell(readinessScore: 7, summary: "Your readiness is solid thanks to yesterday’s 55 minutes of exercise and a brisk 5 km of walking, but under-7 hours of sleep and elevated sodium intake slightly drag your score down.")
    }
  }
}
