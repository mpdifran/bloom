//
//  MenstrualHealthData.swift
//  Bloom
//
//  Created by Assistant on 2025-01-25.
//

import Foundation

struct MenstrualHealthData: SendableNetworkModel {
  let currentCyclePhase: String?    // follicular, luteal, menstrual, ovulatory
  let dayInCycle: Int?              // Day number in current cycle
  let daysSinceLastPeriod: Int?     // Days since period started
  let averageCycleLength: MetricWithTrend?  // "28 days" with regularity trend
  let predictedNextPeriod: String?  // "in 14 days"
}