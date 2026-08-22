//
//  BowelMovementsTimeOfDayStatCard.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import SFSafeSymbols
import CoreHealth

struct BowelMovementsTimeOfDayStatCard: View {
  let summary: BowelMovementSummary?

  private var mostCommonTimeOfDay: Calendar.TimeOfDay? {
    guard let summary, !summary.bowelMovements.isEmpty else { return nil }
    return summary.timeOfDayDistribution
      .max(by: { $0.value.count < $1.value.count })?
      .key
  }

  private var tintColor: Color {
    guard let timeOfDay = mostCommonTimeOfDay else { return .gray }
    switch timeOfDay {
    case .morning: return .mutedYellow
    case .afternoon: return .mutedOrange
    case .evening: return .mutedPurple
    case .overnight: return .mutedIndigo
    @unknown default: return .orange
    }
  }

  var body: some View {
    if let timeOfDay = mostCommonTimeOfDay {
      StatCard(
        symbol: .sunMaxFill,
        title: "Time Of Day",
        value: timeOfDay.name,
        valueStyle: .largeTinted(String(localized: "Most Common", comment: "Stat card subtitle: the value is the most common one"))
      )
      .tint(tintColor)
    } else {
      StatCard(
        symbol: .sunMaxFill,
        title: "Time Of Day",
        value: String(localized: "No Data", comment: "Stat card value shown when there is no data"),
        valueStyle: .largeTinted(nil)
      )
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        BowelMovementsTimeOfDayStatCard(summary: nil)
        BowelMovementsTimeOfDayStatCard(summary: nil)
      }
    }
  }
}
