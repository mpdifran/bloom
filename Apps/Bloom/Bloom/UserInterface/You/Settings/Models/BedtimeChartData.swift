//
//  BedtimeChartData.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-12-29.
//

import Foundation

struct BedtimeDataPoint: Identifiable, Hashable, Sendable {
  let date: Date
  let minutesFromMidnight: Double

  var id: Date { date }
}

enum BedtimeTrend: String, Sendable {
  case consistent = "Consistent"
  case inconsistent = "Inconsistent"
  case trendingEarlier = "Trending Earlier"
  case trendingLater = "Trending Later"

  /// What to show the user. The raw values are wire/analytics identifiers and must stay English -
  /// displaying them directly is why this read "Trending Later" in every language.
  var displayName: String {
    switch self {
    case .consistent:
      String(localized: "Consistent", comment: "Bedtime trend shown on the sleep card")
    case .inconsistent:
      String(localized: "Inconsistent", comment: "Bedtime trend shown on the sleep card")
    case .trendingEarlier:
      String(localized: "Trending Earlier", comment: "Bedtime trend shown on the sleep card")
    case .trendingLater:
      String(localized: "Trending Later", comment: "Bedtime trend shown on the sleep card")
    }
  }
}

struct BedtimeChartData: Hashable, Sendable {
  let dataPoints: [BedtimeDataPoint]
  let trend: BedtimeTrend
}
