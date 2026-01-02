//
//  BowelMovementsSection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols
import DataContainer

struct BowelMovementsSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let summary: BowelMovementMonthlySummary?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.bowelMovements.systemImage), title: "Bowel Movements", subtitle: "Last 7 Days") {
      HStack {
        overallScoreCard
        regularityCard
      }

      HStack {
        stoolTypeCard
        timeOfDayCard
      }
    }
  }

  private func navigateToDetails() {
    presentedNavigationDestination = BowelMovementsDetailView().asAny
  }
}

private extension BowelMovementsSection {

  var overallScoreCard: some View {
    BowelMovementsScoreStatCard(summary: summary)
      .onTapGesture { navigateToDetails() }
  }

  var regularityCard: some View {
    BowelMovementsRegularityStatCard(summary: summary)
      .onTapGesture { navigateToDetails() }
  }

  var stoolTypeCard: some View {
    BowelMovementsStoolTypeStatCard(summary: summary)
      .onTapGesture { navigateToDetails() }
  }

  var timeOfDayCard: some View {
    BowelMovementsTimeOfDayStatCard(summary: summary)
      .onTapGesture { navigateToDetails() }
  }
}

private extension BowelMovementMonthlySummary.RegularityLevel {

  var statusLevel: StatusIndicatorCard.Level {
    switch self {
    case .excellent: .optimal
    case .good: .high
    case .moderate: .medium
    case .poor, .veryPoor, .unknown: .low
    @unknown default: .low
    }
  }
}

private extension BowelMovementMonthlySummary.Rating {

  var displayColor: Color {
    switch self {
    case .poor: .mutedRed
    case .fair: .mutedYellow
    case .good: .mutedGreen
    case .excellent: .mutedBlue
    @unknown default: .green
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      BowelMovementsSection(
        presentedNavigationDestination: .constant(nil),
        summary: nil
      )
    }
  }
}
