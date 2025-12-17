//
//  YearInBloomMenstrualCycleCard.swift
//  Bloom
//
//  Created by Claude on 2025-12-17.
//

import SwiftUI
import CoreHealth
import BloomUI
import SFSafeSymbols

struct YearInBloomMenstrualCycleCard: View {
  let stats: YearInBloomMenstrualStats

  var body: some View {
    YearInBloomCard(
      title: "Cycle Insights",
      focusStat: "\(Int(stats.averageCycleDuration)) days",
      focusStatLabel: "Avg Cycle",
      includeDivider: false,
      foregroundFill: .white,
      backgroundFill: .mutedPink.gradient
    ) {
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
        cycleRangeCard
        activityCard
        heartRateCard
        sleepEfficiencyCard
      }
    }
  }
}

// MARK: - Sub Cards

private extension YearInBloomMenstrualCycleCard {

  var cycleRangeCard: some View {
    VStack(alignment: .leading, spacing: 0) {
      Label("Cycle Range", systemSymbol: .calendar)
        .font(.caption)
        .foregroundStyle(.white.opacity(0.8))

      Spacer()

      if let shortest = stats.shortestCycle, let longest = stats.longestCycle {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
          Text("\(shortest.duration)")
            .font(.title2)
            .bold()
          Text("-")
            .font(.title3)
          Text("\(longest.duration)")
            .font(.title2)
            .bold()
          Text("days")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
        }
        .fontDesign(.rounded)
      } else {
        Text("—")
          .font(.title2)
          .bold()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
  }

  var activityCard: some View {
    VStack(alignment: .leading, spacing: 0) {
      Label("Follicular Activity", systemSymbol: .figureCooldown)
        .font(.caption)
        .foregroundStyle(.white.opacity(0.8))

      Spacer()

      if let increase = stats.follicularActivityIncrease {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          Text(increase >= 0 ? "+" : "")
            .font(.title3)
          Text(String(format: "%.1f", increase))
            .font(.title2)
            .bold()
          Text("%")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
        }
        .fontDesign(.rounded)
        Text("vs baseline")
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.6))
      } else {
        Text("—")
          .font(.title2)
          .bold()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
  }

  var heartRateCard: some View {
    VStack(alignment: .leading, spacing: 0) {
      Label("Luteal HR", systemSymbol: .heartFill)
        .font(.caption)
        .foregroundStyle(.white.opacity(0.8))

      Spacer()

      if let change = stats.lutealRestingHRChange {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          Text(change >= 0 ? "+" : "")
            .font(.title3)
          Text(String(format: "%.1f", change))
            .font(.title2)
            .bold()
          Text("bpm")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
        }
        .fontDesign(.rounded)
        Text("resting HR")
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.6))
      } else {
        Text("—")
          .font(.title2)
          .bold()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
  }

  var sleepEfficiencyCard: some View {
    VStack(alignment: .leading, spacing: 0) {
      Label("Luteal Sleep", systemSymbol: .moonFill)
        .font(.caption)
        .foregroundStyle(.white.opacity(0.8))

      Spacer()

      if let change = stats.lutealSleepEfficiencyChange {
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          Text(change >= 0 ? "+" : "")
            .font(.title3)
          Text(String(format: "%.1f", change))
            .font(.title2)
            .bold()
          Text("%")
            .font(.caption)
            .foregroundStyle(.white.opacity(0.8))
        }
        .fontDesign(.rounded)
        Text("efficiency")
          .font(.caption2)
          .foregroundStyle(.white.opacity(0.6))
      } else {
        Text("—")
          .font(.title2)
          .bold()
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 14))
  }
}

// MARK: - Preview

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      YearInBloomMenstrualCycleCard(
        stats: .preview
      )
    }
  }
}
