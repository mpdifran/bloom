//
//  BowelMovementsRegularityStatCard.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth

struct BowelMovementsRegularityStatCard: View {
  let summary: BowelMovementSummary?

  var body: some View {
    if let summary {
      let regularity = summary.regularityLevel(for: summary.coefficientOfVariation)
      StatCard(
        symbol: .clockFill,
        title: "Regularity",
        value: regularity.rawValue,
        valueStyle: .largeTinted("Last 7 Days")
      )
      .tint(regularity.color)
    } else {
      StatCard(
        symbol: .clockFill,
        title: "Regularity",
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
        BowelMovementsRegularityStatCard(summary: nil)
        BowelMovementsRegularityStatCard(summary: nil)
      }
    }
  }
}
