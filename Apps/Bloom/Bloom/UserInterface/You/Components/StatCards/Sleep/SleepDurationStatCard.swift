//
//  SleepDurationStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-29.
//

import SwiftUI

struct SleepDurationStatCard: View {
  let data: SleepDurationChartData?

  private var formattedDuration: String? {
    guard let data else { return nil }
    let totalMinutes = Int(data.average / 60)
    // Locale-aware duration: hand-built "3h 45m" hardcoded English unit abbreviations.
    return Duration.seconds(Int(totalMinutes) * 60)
      .formatted(.units(allowed: [.hours, .minutes], width: .narrow))
  }

  var body: some View {
    if let data {
      StatCard(
        symbol: .clockFill,
        title: "Duration",
        value: formattedDuration ?? String(localized: "No Data", comment: "Stat card value shown when there is no data"),
        valueStyle: .largeTinted(String(localized: "7 day avg", comment: "Stat card subtitle: the value is a seven day average"))
      ) {
        barChart
      }
      .tint(.coreSleep)
    } else {
      StatCard(
        symbol: .clockFill,
        title: "Duration",
        value: String(localized: "No Data", comment: "Stat card value shown when there is no data"),
        valueStyle: .largeTinted(nil)
      )
      .tint(.gray)
    }
  }
}

private extension SleepDurationStatCard {

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
              .fill(Color.coreSleep)
              .frame(height: max(height, value > 0 ? 4 : 2))
              .opacity(value > 0 ? 1 : 0.3)
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
        SleepDurationStatCard(data: SleepDurationChartData(
          dailyValues: [25380, 27000, 23400, 28800, 26100, 24300, 27900],
          average: 26126
        ))
        SleepDurationStatCard(data: nil)
      }
      HStack {
        SleepDurationStatCard(data: SleepDurationChartData(
          dailyValues: [0, 27000, 23400, 0, 26100, 24300, 0],
          average: 25200
        ))
        SleepDurationStatCard(data: SleepDurationChartData(
          dailyValues: [28800, 28800, 28800, 28800, 28800, 28800, 28800],
          average: 28800
        ))
      }
    }
  }
}
