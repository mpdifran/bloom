//
//  SleepScoreStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-29.
//

import SwiftUI

struct SleepScoreStatCard: View {
  let score: Double?

  var body: some View {
    StatCard(
      symbol: .moonStarsFill,
      title: "Sleep Score",
      includePadding: false
    ) {
      sleepGauge
        .padding(.bottom, 8)
    }
    .tint(score == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.awakeSleep))
  }
}

private extension SleepScoreStatCard {

  @ViewBuilder
  var sleepGauge: some View {
    if let score {
      StatGauge(
        progress: score / 100,
        label: "\(Int(score))",
        color: .awakeSleep
      )
    } else {
      StatGauge(
        progress: 0,
        label: "--",
        color: .gray
      )
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        SleepScoreStatCard(score: 80)
        SleepScoreStatCard(score: nil)
      }
    }
  }
}
