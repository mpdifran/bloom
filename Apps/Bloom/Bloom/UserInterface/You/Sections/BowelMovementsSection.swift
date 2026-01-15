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
  let summary: BowelMovementSummary?

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

private extension BowelMovementSummary.Rating {

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
