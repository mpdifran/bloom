//
//  AlcoholSummary.swift
//  CoreHealth
//
//  Created by Claude on 2026-01-24.
//

import SwiftUI
import HealthKit

public enum AlcoholRiskLevel: String, CaseIterable, Sendable {
  case low
  case moderate
  case elevated
  case high

  public var displayName: String {
    switch self {
    case .low:
      "Low Risk"
    case .moderate:
      "Moderate"
    case .elevated:
      "Elevated"
    case .high:
      "High Risk"
    }
  }

  public var color: Color {
    switch self {
    case .low:
      .vitalGreat
    case .moderate:
      .vitalGood
    case .elevated:
      .vitalWarning
    case .high:
      .vitalSevere
    }
  }
}

public struct AlcoholSummary: Sendable, Equatable {
  public let weeklyTotal: Int
  public let dailyData: [DailyAlcoholData]
  public let bingeDays: Int
  public let heavyDays: Int
  public let hasData: Bool

  public struct DailyAlcoholData: Sendable, Equatable, Identifiable {
    public let date: Date
    public let drinks: Int

    public var id: Date { date }

    public init(date: Date, drinks: Int) {
      self.date = date
      self.drinks = drinks
    }
  }

  public init(
    weeklyTotal: Int,
    dailyData: [DailyAlcoholData],
    bingeDays: Int,
    heavyDays: Int
  ) {
    self.weeklyTotal = weeklyTotal
    self.dailyData = dailyData
    self.bingeDays = bingeDays
    self.heavyDays = heavyDays
    self.hasData = !dailyData.isEmpty && weeklyTotal > 0
  }

  public static var empty: AlcoholSummary {
    AlcoholSummary(weeklyTotal: 0, dailyData: [], bingeDays: 0, heavyDays: 0)
  }

  /// Calculate the alcohol risk level based on binge drinking and total consumption
  public var riskLevel: AlcoholRiskLevel {
    // High risk: 2+ binge days or any heavy drinking days
    if heavyDays >= 1 || bingeDays >= 2 {
      return .high
    }
    // Elevated: 1 binge day or weekly total > 14
    if bingeDays >= 1 || weeklyTotal > 14 {
      return .elevated
    }
    // Moderate: weekly total > 7
    if weeklyTotal > 7 {
      return .moderate
    }
    // Low: 7 or fewer drinks per week with no binge days
    return .low
  }

  /// Calculate the risk score used for bio age calculation (0.0 - 1.0)
  public func riskScore(for sex: HKBiologicalSex) -> Double {
    let bingeThreshold = (sex == .male) ? 5.0 : 4.0

    // Recalculate binge days based on actual threshold for the given sex
    let actualBingeDays = dailyData.filter { Double($0.drinks) >= bingeThreshold }.count

    let bingeComponent = min(1.0, Double(actualBingeDays) / 2.0)
    let heavyComponent = min(1.0, Double(heavyDays) / 1.0) * 0.5
    let totalComponent = weeklyTotal > 7 ? min(1.0, Double(weeklyTotal - 7) / 14.0) * 0.5 : 0.0

    return min(1.0, max(0.0, 0.6 * bingeComponent + 0.2 * heavyComponent + 0.2 * totalComponent))
  }

  public var weeklyTotalDisplayString: String {
    if weeklyTotal == 1 {
      return "1 drink"
    }
    return "\(weeklyTotal) drinks"
  }
}
