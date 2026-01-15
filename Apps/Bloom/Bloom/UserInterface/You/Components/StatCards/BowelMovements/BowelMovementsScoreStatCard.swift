//
//  BowelMovementsScoreStatCard.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth

struct BowelMovementsScoreStatCard: View {
  let summary: BowelMovementSummary?

  var body: some View {
    if let summary, let rating = summary.rating {
      StatCard(
        symbol: .chartBarFill,
        title: "Overall Score",
        value: rating.name,
        valueStyle: .largeTinted("Last 7 Days")
      )
      .tint(rating.color)
    } else {
      StatCard(
        symbol: .chartBarFill,
        title: "Overall Score",
        value: "No Data",
        valueStyle: .largeTinted(nil)
      )
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      // Note: BowelMovementSummary requires BowelMovementDTO with PersistentIdentifier
      // which cannot be easily mocked. Use the app with real data for full preview.
      HStack {
        BowelMovementsScoreStatCard(summary: nil)
        BowelMovementsScoreStatCard(summary: nil)
      }
    }
  }
}
