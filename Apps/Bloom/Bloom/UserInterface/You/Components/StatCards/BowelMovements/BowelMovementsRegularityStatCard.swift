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
        valueStyle: .largeTinted(String(localized: "Last 7 Days", comment: "Stat card subtitle: the value covers the last seven days"))
      )
      .tint(regularity.color)
    } else {
      StatCard(
        symbol: .clockFill,
        title: "Regularity",
        value: String(localized: "No Data", comment: "Stat card value shown when there is no data"),
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
