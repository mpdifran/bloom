//
//  YearInBloomBodyWeightStats+Preview.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-17.
//

import Foundation

public extension YearInBloomBodyWeightStats {
  static var preview: YearInBloomBodyWeightStats {
    let calendar = Calendar.current

    // Generate weight data with a general downward trend (weight loss)
    // Starting around 185 lbs and ending around 175 lbs
    let baseWeight: Double = 185.0  // in pounds
    let monthlyWeightData = (1...12).map { month in
      let date = calendar.date(from: DateComponents(year: 2024, month: month, day: 15))!
      // Gradual weight loss with some variation
      let trendOffset = Double(month - 1) * -0.83  // ~10 lbs loss over year
      let baseForMonth = baseWeight + trendOffset
      let minWeight = baseForMonth + Double.random(in: -2.0...0)      // 2 lbs below
      let maxWeight = baseForMonth + Double.random(in: 0...3.0)       // 3 lbs above
      let averageWeight = (minWeight + maxWeight) / 2

      return MonthlyWeightData(
        date: date,
        minWeight: minWeight,
        maxWeight: maxWeight,
        averageWeight: averageWeight
      )
    }

    // Generate body fat data with slight downward trend
    let monthlyBodyFatData = (1...12).map { month in
      let date = calendar.date(from: DateComponents(year: 2024, month: month, day: 15))!
      // Start around 22% and end around 19%
      let baseFat = 0.22 - (Double(month - 1) * 0.0025)
      let bodyFat = baseFat + Double.random(in: -0.01...0.01)
      return MonthlyBodyFatData(date: date, averageBodyFat: bodyFat)
    }

    return YearInBloomBodyWeightStats(
      year: 2024,
      monthlyWeightData: monthlyWeightData,
      monthlyBodyFatData: monthlyBodyFatData,
      yearStartWeight: monthlyWeightData.first?.averageWeight,
      yearEndWeight: monthlyWeightData.last?.averageWeight,
      generatedDate: .now
    )
  }
}
