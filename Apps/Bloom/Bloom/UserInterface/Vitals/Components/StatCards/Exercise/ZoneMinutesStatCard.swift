//
//  ZoneMinutesStatCard.swift
//  Bloom
//
//  Created by Assistant on 2025-01-02.
//

import SwiftUI
import SFSafeSymbols

struct ZoneMinutesStatCard: View {
  let data: ZoneMinutesData?

  private var valueText: String {
    guard let data else { return "No Data" }
    return "\(Int(data.weeklyTotal)) min"
  }

  private var subtitle: String? {
    guard let data else { return nil }
    if data.meetsGoal {
      return "Goal Met"
    } else {
      let remaining = Int(data.goal - data.weeklyTotal)
      return "\(remaining) min to go"
    }
  }

  private var trend: StatCardTrend? {
    guard let data else { return nil }
    if data.meetsGoal {
      return .ok
    } else if data.weeklyTotal < data.goal / 2 {
      return .critical
    } else {
      return .warning
    }
  }

  private var tintColor: Color {
    guard let data else { return .gray }
    if data.meetsGoal {
      return .heartRateZone3
    } else if data.weeklyTotal < data.goal / 2 {
      return .heartRateZone5
    } else {
      return .heartRateZone4
    }
  }

  var body: some View {
    StatCard(
      symbol: .stopwatchFill,
      title: "Zone Minutes",
      value: valueText,
      valueStyle: .largeTinted(subtitle),
      trend: trend
    ) {
      barChart
    }
    .tint(tintColor)
  }
}

private extension ZoneMinutesStatCard {

  @ViewBuilder
  var barChart: some View {
    if let data, data.dailyValues.isNotEmpty {
      let maxValue = data.dailyValues.max() ?? 1

      GeometryReader { geometry in
        HStack(alignment: .bottom, spacing: 2) {
          ForEach(0..<7, id: \.self) { index in
            let value = data.dailyValues[safe: index] ?? 0
            let height = maxValue > 0 ? (value / maxValue) * geometry.size.height : 0

            RoundedRectangle(cornerRadius: 2)
              .fill(tintColor)
              .frame(height: max(height, 2))
          }
        }
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        ZoneMinutesStatCard(data: previewZoneMinutesGoalMet)
        ZoneMinutesStatCard(data: previewZoneMinutesBelowGoal)
      }
      HStack {
        ZoneMinutesStatCard(data: previewZoneMinutesExact)
        ZoneMinutesStatCard(data: nil)
      }
    }
  }
}

private let previewZoneMinutesGoalMet = ZoneMinutesData(
  dailyValues: [30, 25, 40, 20, 35, 15, 25],
  weeklyTotal: 190
)

private let previewZoneMinutesBelowGoal = ZoneMinutesData(
  dailyValues: [15, 10, 20, 5, 25, 10, 15],
  weeklyTotal: 100
)

private let previewZoneMinutesExact = ZoneMinutesData(
  dailyValues: [20, 22, 25, 18, 30, 15, 20],
  weeklyTotal: 150
)
