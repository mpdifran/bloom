//
//  YearInBloomMenstrualStats+Preview.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-17.
//

import Foundation

public extension YearInBloomMenstrualStats {
  static var preview: YearInBloomMenstrualStats {
    YearInBloomMenstrualStats(
      year: 2024,
      totalCycles: 13,
      averageCycleDuration: 28.5,
      shortestCycle: CycleExtreme(
        duration: 24,
        startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 3, day: 15))!
      ),
      longestCycle: CycleExtreme(
        duration: 34,
        startDate: Calendar.current.date(from: DateComponents(year: 2024, month: 8, day: 2))!
      ),
      follicularActivityIncrease: 12.5,
      lutealRestingHRChange: 3.2,
      lutealSleepEfficiencyChange: -4.5,
      generatedDate: .now
    )
  }
}
