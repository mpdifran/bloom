//
//  YearInBloomMenstrualStats+Preview.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-17.
//

import Foundation

public extension YearInBloomMenstrualStats {
  static var preview: YearInBloomMenstrualStats {
    let calendar = Calendar.current

    let monthlyPhaseActivityData = (1...12).map { month in
      let date = calendar.date(from: DateComponents(year: 2024, month: month, day: 15))!
      let follicularActivity = 0.35 + Double.random(in: 0.05...0.15)
      let otherActivity = 0.30 + Double.random(in: 0.02...0.08)
      return MonthlyPhaseActivityData(
        date: date,
        follicularActivityLevel: follicularActivity,
        otherActivityLevel: otherActivity
      )
    }

    return YearInBloomMenstrualStats(
      year: 2024,
      totalCycles: 13,
      averageCycleDuration: 28.5,
      averagePeriodLength: 5.2,
      shortestCycle: CycleExtreme(
        duration: 24,
        startDate: calendar.date(from: DateComponents(year: 2024, month: 3, day: 15))!
      ),
      longestCycle: CycleExtreme(
        duration: 34,
        startDate: calendar.date(from: DateComponents(year: 2024, month: 8, day: 2))!
      ),
      follicularActivityIncrease: 12.5,
      lutealRestingHRChange: 3.2,
      lutealSleepEfficiencyChange: -4.5,
      monthlyPhaseActivityData: monthlyPhaseActivityData,
      generatedDate: .now
    )
  }
}
