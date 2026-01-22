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
    .tint(score == nil ? AnyShapeStyle(.gray) : AnyShapeStyle(.coreSleep))
  }
}

private extension SleepScoreStatCard {

  var sleepGauge: some View {
    StatGauge(
      progress: (score ?? 0) / 100,
      color: score == nil ? .gray : .coreSleep
    ) {
      MicroSleepScoreView(score: score.map { Int($0) })
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
