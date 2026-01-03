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
}

struct BedtimeChartData: Hashable, Sendable {
  let dataPoints: [BedtimeDataPoint]
  let trend: BedtimeTrend
}
