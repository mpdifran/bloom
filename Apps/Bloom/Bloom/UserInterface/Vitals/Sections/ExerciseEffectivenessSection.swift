//
//  ExerciseEffectivenessSection.swift
//  Bloom
//
//  Created by Assistant on 2024-12-29.
//

import SwiftUI
import CoreHealth
import SFSafeSymbols
import DataContainer

struct ExerciseEffectivenessSection: View {
  @Binding var presentedNavigationDestination: AnyView?
  let summary: ExerciseEffectivenessMonthlySummary?

  var body: some View {
    StatSection(symbol: SFSymbol(rawValue: VitalModel.Kind.exerciseEffectiveness.systemImage), title: "Exercise Effectiveness", subtitle: "Last 30 Days") {
      HStack {
        zoneMinutesCard
        zoneDistributionCard
      }

      todaysExercisesCard
    }
  }

  private func navigateToDetails() {
    presentedNavigationDestination = ExerciseEffectivenessView().asAny
  }
}

private extension ExerciseEffectivenessSection {

  @ViewBuilder
  var zoneMinutesCard: some View {
    if let details = summary?.details, !details.hasNoData {
      let zoneMinutes = details.overallHeartZoneDistribution.scaledDurationSum.doubleValue(for: .minute())
      let goal: Double = 600
      let progress = min(zoneMinutes / goal, 1.0)
      GaugeCard(
        title: "Zone Minutes",
        value: "\(Int(zoneMinutes))/\(Int(goal))",
        progress: progress,
        symbol: .heartFill,
        color: .red
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Zone Minutes", symbol: .heartFill)
        .onTapGesture { navigateToDetails() }
    }
  }

  @ViewBuilder
  var zoneDistributionCard: some View {
    // TODO: Show zone distribution as mini bars
    if summary?.details.hasNoData == false {
      StatusIndicatorCard(
        title: "Zone Distribution",
        status: summary?.details.level.name ?? "Unknown",
        level: summary?.details.level.statusLevel ?? .medium,
        symbol: .chartBarFill
      )
      .onTapGesture { navigateToDetails() }
    } else {
      NoDataCard(title: "Zone Distribution", symbol: .chartBarFill)
        .onTapGesture { navigateToDetails() }
    }
  }

  @ViewBuilder
  var todaysExercisesCard: some View {
    TodaysExercisesCard()
      .onTapGesture { navigateToDetails() }
  }
}

private extension ExerciseEffectivenessMonthlySummary.Level {

  var statusLevel: StatusIndicatorCard.Level {
    switch self {
    case .minimal: .low
    case .moderate: .medium
    case .sufficient: .high
    case .high: .optimal
    }
  }
}

// MARK: - Today's Exercises Card

struct TodaysExercisesCard: View {
  // TODO: Fetch today's workouts

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Image(systemSymbol: .figureMixedCardio)
          .font(.caption)
          .foregroundStyle(.orange)

        Text("Today's Exercises")
          .font(.caption)
          .fontWeight(.medium)
          .foregroundStyle(.secondary)

        Spacer()

        Button {
          // TODO: Navigate to exercise list
        } label: {
          Text("See More")
            .font(.caption)
            .fontWeight(.medium)
        }
      }

      // Placeholder for exercises
      VStack(spacing: 8) {
        Text("No exercises logged today")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, minHeight: 60)
    }
    .cardContainer(fill: .background)
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      ExerciseEffectivenessSection(
        presentedNavigationDestination: .constant(nil),
        summary: nil
      )
    }
  }
}
