//
//  CycleTrackingSection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols
import BloomFoundation
import DataContainer

struct CycleTrackingSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let summary: MenstrualSummary?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.cycleTracking.systemImage), title: "Cycle Tracking", subtitle: "Current Cycle") {
      HStack {
        cycleDurationCard
        currentPhaseCard
      }

      nextPeriodCard
    }
  }

  private func navigateToDetails() {
    presentedNavigationDestination = MenstruationDetailView().asAny
  }
}

private extension CycleTrackingSection {

  @ViewBuilder
  var cycleDurationCard: some View {
    if let duration = summary?.averageCycleDuration {
      BigNumberCard(
        title: "Cycle Duration",
        value: "\(Int(duration))",
        unit: "days",
        symbol: .circleGridCross,
        color: .pink
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Cycle Duration", symbol: .circleGridCross)
        .onTapGesture { navigateToDetails() }
    }
  }

  @ViewBuilder
  var currentPhaseCard: some View {
    if let phase = summary?.currentPhase(), phase != .unknown {
      CategoryLabelCard(
        title: "Current Phase",
        value: phase.name,
        symbol: .circleDottedAndCircle,
        color: summary?.color ?? .pink
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Current Phase", symbol: .circleDottedAndCircle)
        .onTapGesture { navigateToDetails() }
    }
  }

  @ViewBuilder
  var nextPeriodCard: some View {
    if let nextPeriod = summary?.nextPredictedPeriodDate {
      let formatter = DateFormatter.justDateShort
      BigNumberCard(
        title: "Next Period",
        value: formatter.string(from: nextPeriod),
        symbol: .calendarBadgeClock,
        color: .pink
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Next Period", symbol: .calendarBadgeClock)
        .onTapGesture { navigateToDetails() }
    }
  }
}

// MARK: - Category Label Card

struct CategoryLabelCard: View {
  let title: String
  let value: String
  let symbol: SFSymbol
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Image(systemSymbol: symbol)
          .font(.caption)
          .foregroundStyle(color)

        Text(title)
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Text(value)
        .font(.system(size: 20, weight: .semibold, design: .rounded))
        .foregroundStyle(color)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .aspectRatio(1, contentMode: .fit)
    .cardContainer(fill: .background)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      CycleTrackingSection(
        presentedNavigationDestination: .constant(nil),
        summary: nil
      )
    }
  }
}
