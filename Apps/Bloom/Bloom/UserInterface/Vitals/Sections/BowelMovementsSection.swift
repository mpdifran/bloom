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

      timeOfDayCard
    }
  }

  private func navigateToDetails() {
    presentedNavigationDestination = BowelMovementsDetailView().asAny
  }
}

private extension BowelMovementsSection {

  @ViewBuilder
  var overallScoreCard: some View {
    if let summary, let rating = summary.rating {
      GaugeCard(
        title: "Overall Score",
        value: rating.name,
        progress: summary.score,
        symbol: .chartBarFill,
        color: rating.displayColor
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Overall Score", symbol: .chartBarFill)
        .onTapGesture { navigateToDetails() }
    }
  }

  @ViewBuilder
  var regularityCard: some View {
    if let summary {
      let regularity = summary.regularityLevel(for: summary.coefficientOfVariation)
      StatusIndicatorCard(
        title: "Regularity",
        status: regularity.rawValue,
        level: regularity.statusLevel,
        symbol: .clockFill
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Regularity", symbol: .clockFill)
        .onTapGesture { navigateToDetails() }
    }
  }

  @ViewBuilder
  var timeOfDayCard: some View {
    if let summary, !summary.bowelMovements.isEmpty {
      let avgHour = summary.bowelMovements
        .map { Calendar.current.component(.hour, from: $0.date) }
        .reduce(0, +) / summary.bowelMovements.count
      let period = avgHour < 12 ? "AM" : "PM"
      let displayHour = avgHour == 0 ? 12 : (avgHour > 12 ? avgHour - 12 : avgHour)
      BigNumberCard(
        title: "Avg Time",
        value: "\(displayHour):00",
        unit: period,
        symbol: .sunMaxFill,
        color: .orange
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Avg Time", symbol: .sunMaxFill)
        .onTapGesture { navigateToDetails() }
    }
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
