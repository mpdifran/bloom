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
  let predictedNextPeriodDate: String?  // ISO date string of predicted next period
  let daysUntilPredictedPeriod: Int?    // Days until predicted period
  let isMenstruating: Bool?         // Whether currently menstruating
  let dayInCurrentPhase: Int?       // Day number within current phase (not cycle)
}