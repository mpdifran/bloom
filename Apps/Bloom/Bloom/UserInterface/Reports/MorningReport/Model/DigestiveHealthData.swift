//
//  DigestiveHealthData.swift
//  Bloom
//
//  Created by Assistant on 2025-01-25.
//

import Foundation

struct DigestiveHealthData: SendableNetworkModel {
  let yesterdayMovements: [BowelMovementSample]
  let averageDailyMovements: MetricWithTrend?
  let regularityScore: MetricWithTrend?
  let daysSinceLastMovement: Int?
}

struct BowelMovementSample: SendableNetworkModel {
  let time: String          // "9:30 AM"
  let bristolScore: Int     // 1-7
  let duration: String      // "< 5 min", "5-10 min", etc.
}