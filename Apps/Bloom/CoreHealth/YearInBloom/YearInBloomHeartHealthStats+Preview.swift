//
//  YearInBloomHeartHealthStats+Preview.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-17.
//

import Foundation

public extension YearInBloomHeartHealthStats {
  static var preview: YearInBloomHeartHealthStats {
    let calendar = Calendar.current

    let monthlyHeartRateData = (1...12).map { month in
      let date = calendar.date(from: DateComponents(year: 2024, month: month, day: 15))!
      let restingHR: Double = 58 + Double.random(in: -3...5)
      let minHR: Double = 48 + Double.random(in: -5...5)
      let maxHR: Double = 165 + Double.random(in: -10...15)
      return MonthlyHeartRateData(
        date: date,
        averageRestingHR: restingHR,
        averageMinHR: minHR,
        averageMaxHR: maxHR
      )
    }

    let monthlyHRVData = (1...12).map { month in
      let date = calendar.date(from: DateComponents(year: 2024, month: month, day: 15))!
      let hrv: Double = 45 + Double.random(in: -10...15)
      return MonthlyHRVData(date: date, averageHRV: hrv)
    }

    return YearInBloomHeartHealthStats(
      year: 2024,
      monthlyHeartRateData: monthlyHeartRateData,
      monthlyHRVData: monthlyHRVData,
      yearlyAverageRestingHR: 60.5,
      generatedDate: .now
    )
  }
}
