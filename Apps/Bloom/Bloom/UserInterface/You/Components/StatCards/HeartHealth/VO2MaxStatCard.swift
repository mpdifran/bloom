//
//  VO2MaxStatCard.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-30.
//

import SwiftUI

struct VO2MaxStatCard: View {
  let trendData: VO2MaxTrendData?

  var body: some View {
    StatCard(
      symbol: .lungs,
      title: "VO₂ Max",
      value: formattedValue,
      valueStyle: .largeTinted(trendText),
      trend: statCardTrend
    )
    .tint(trendData == nil ? .gray : .mutedLightBlue)
  }
}

private extension VO2MaxStatCard {

  var formattedValue: String {
    guard let value = trendData?.latestValue else { return "No Data" }
    return String(format: "%.1f", value)
  }

  var trendText: String? {
    trendData?.trend.displayText
  }

  var statCardTrend: StatCardTrend? {
    guard let trend = trendData?.trend else { return nil }
    switch trend {
    case .improving: return .trendingUp
    case .constant: return .constant
    case .declining: return .trendingDown
    }
  }
}

#Preview {
  PreviewEnvironment {
    BloomScrollView {
      HStack {
        VO2MaxStatCard(trendData: VO2MaxTrendData(latestValue: 42.5, trend: .improving))
        VO2MaxStatCard(trendData: VO2MaxTrendData(latestValue: 38.2, trend: .constant))
      }

      HStack {
        VO2MaxStatCard(trendData: VO2MaxTrendData(latestValue: 35.0, trend: .declining))
        VO2MaxStatCard(trendData: nil)
      }
    }
  }
}
