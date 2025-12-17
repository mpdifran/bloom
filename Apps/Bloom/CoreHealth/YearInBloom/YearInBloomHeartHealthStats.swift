//
//  YearInBloomHeartHealthStats.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-17.
//

import Foundation

// MARK: - Main Stats Model

public struct YearInBloomHeartHealthStats: Sendable, Codable, Hashable {
  public let year: Int
  public let monthlyHeartRateData: [MonthlyHeartRateData]
  public let monthlyHRVData: [MonthlyHRVData]
  public let yearlyAverageRestingHR: Double?
  public let generatedDate: Date

  public init(
    year: Int,
    monthlyHeartRateData: [MonthlyHeartRateData],
    monthlyHRVData: [MonthlyHRVData],
    yearlyAverageRestingHR: Double?,
    generatedDate: Date
  ) {
    self.year = year
    self.monthlyHeartRateData = monthlyHeartRateData
    self.monthlyHRVData = monthlyHRVData
    self.yearlyAverageRestingHR = yearlyAverageRestingHR
    self.generatedDate = generatedDate
  }
}

// MARK: - Monthly Heart Rate Data

public struct MonthlyHeartRateData: Identifiable, Sendable, Codable, Hashable {
  public var id: Date { date }
  public let date: Date
  public let averageRestingHR: Double?
  public let averageMaxHR: Double?

  public init(date: Date, averageRestingHR: Double?, averageMaxHR: Double?) {
    self.date = date
    self.averageRestingHR = averageRestingHR
    self.averageMaxHR = averageMaxHR
  }
}

// MARK: - Monthly HRV Data

public struct MonthlyHRVData: Identifiable, Sendable, Codable, Hashable {
  public var id: Date { date }
  public let date: Date
  public let averageHRV: Double?

  public init(date: Date, averageHRV: Double?) {
    self.date = date
    self.averageHRV = averageHRV
  }
}
