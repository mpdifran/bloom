//
//  YearInBloomBodyWeightStats.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-17.
//

import Foundation

public struct YearInBloomBodyWeightStats: Sendable, Codable, Hashable {
  public let year: Int
  public let monthlyWeightData: [MonthlyWeightData]
  public let monthlyBodyFatData: [MonthlyBodyFatData]
  public let yearStartWeight: Double?  // First month with data (average, in grams)
  public let yearEndWeight: Double?    // Last month with data (average, in grams)
  public let generatedDate: Date

  public init(
    year: Int,
    monthlyWeightData: [MonthlyWeightData],
    monthlyBodyFatData: [MonthlyBodyFatData],
    yearStartWeight: Double?,
    yearEndWeight: Double?,
    generatedDate: Date
  ) {
    self.year = year
    self.monthlyWeightData = monthlyWeightData
    self.monthlyBodyFatData = monthlyBodyFatData
    self.yearStartWeight = yearStartWeight
    self.yearEndWeight = yearEndWeight
    self.generatedDate = generatedDate
  }
}

// MARK: - Monthly Weight Data

public struct MonthlyWeightData: Sendable, Codable, Hashable, Identifiable {
  public var id: Date { date }
  public let date: Date
  public let minWeight: Double?      // in grams (base unit)
  public let maxWeight: Double?      // in grams (base unit)
  public let averageWeight: Double?  // in grams (for calculating year change)

  public init(
    date: Date,
    minWeight: Double?,
    maxWeight: Double?,
    averageWeight: Double?
  ) {
    self.date = date
    self.minWeight = minWeight
    self.maxWeight = maxWeight
    self.averageWeight = averageWeight
  }
}

// MARK: - Monthly Body Fat Data

public struct MonthlyBodyFatData: Sendable, Codable, Hashable, Identifiable {
  public var id: Date { date }
  public let date: Date
  public let averageBodyFat: Double?  // as percentage (0-1)

  public init(date: Date, averageBodyFat: Double?) {
    self.date = date
    self.averageBodyFat = averageBodyFat
  }
}
