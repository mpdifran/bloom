//
//  YearInBloomNutritionStats.swift
//  CoreHealth
//
//  Created by Claude on 2025-12-19.
//

import Foundation

// MARK: - Main Stats Model

public struct YearInBloomNutritionStats: Sendable, Codable, Hashable {
  public let year: Int
  public let monthlyMacroStats: [MonthlyMacroStats]
  public let yearTotals: NutritionYearTotals
  public let generatedDate: Date

  public init(
    year: Int,
    monthlyMacroStats: [MonthlyMacroStats],
    yearTotals: NutritionYearTotals,
    generatedDate: Date
  ) {
    self.year = year
    self.monthlyMacroStats = monthlyMacroStats
    self.yearTotals = yearTotals
    self.generatedDate = generatedDate
  }
}

// MARK: - Monthly Macro Stats

public struct MonthlyMacroStats: Sendable, Codable, Hashable, Identifiable {
  public var id: Int { month }

  public let month: Int // 1-12
  public let daysLogged: Int
  public let averageProteinGrams: Double
  public let averageCarbsGrams: Double
  public let averageFatGrams: Double
  public let averageCalories: Double

  public init(
    month: Int,
    daysLogged: Int,
    averageProteinGrams: Double,
    averageCarbsGrams: Double,
    averageFatGrams: Double,
    averageCalories: Double
  ) {
    self.month = month
    self.daysLogged = daysLogged
    self.averageProteinGrams = averageProteinGrams
    self.averageCarbsGrams = averageCarbsGrams
    self.averageFatGrams = averageFatGrams
    self.averageCalories = averageCalories
  }

  // MARK: - Computed Properties

  public var proteinCalories: Double {
    averageProteinGrams * .caloriesPerGramOfProtein
  }

  public var carbsCalories: Double {
    averageCarbsGrams * .caloriesPerGramOfCarbs
  }

  public var fatCalories: Double {
    averageFatGrams * .caloriesPerGramOfFat
  }

  public var totalMacroCalories: Double {
    proteinCalories + carbsCalories + fatCalories
  }

  public var proteinPercent: Double {
    guard totalMacroCalories > 0 else { return 0 }
    return proteinCalories / totalMacroCalories
  }

  public var carbsPercent: Double {
    guard totalMacroCalories > 0 else { return 0 }
    return carbsCalories / totalMacroCalories
  }

  public var fatPercent: Double {
    guard totalMacroCalories > 0 else { return 0 }
    return fatCalories / totalMacroCalories
  }

  public var monthName: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM"
    let components = DateComponents(month: month)
    guard let date = Calendar.current.date(from: components) else { return "" }
    return formatter.string(from: date)
  }

  public var shortMonthName: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM"
    let components = DateComponents(month: month)
    guard let date = Calendar.current.date(from: components) else { return "" }
    return formatter.string(from: date)
  }
}

// MARK: - Year Totals

public struct NutritionYearTotals: Sendable, Codable, Hashable {
  public let totalDaysLogged: Int
  public let averageProteinGrams: Double
  public let averageCarbsGrams: Double
  public let averageFatGrams: Double
  public let averageCalories: Double

  public init(
    totalDaysLogged: Int,
    averageProteinGrams: Double,
    averageCarbsGrams: Double,
    averageFatGrams: Double,
    averageCalories: Double
  ) {
    self.totalDaysLogged = totalDaysLogged
    self.averageProteinGrams = averageProteinGrams
    self.averageCarbsGrams = averageCarbsGrams
    self.averageFatGrams = averageFatGrams
    self.averageCalories = averageCalories
  }

  // MARK: - Computed Properties

  public var proteinCalories: Double {
    averageProteinGrams * .caloriesPerGramOfProtein
  }

  public var carbsCalories: Double {
    averageCarbsGrams * .caloriesPerGramOfCarbs
  }

  public var fatCalories: Double {
    averageFatGrams * .caloriesPerGramOfFat
  }

  public var totalMacroCalories: Double {
    proteinCalories + carbsCalories + fatCalories
  }

  public var proteinPercent: Double {
    guard totalMacroCalories > 0 else { return 0 }
    return proteinCalories / totalMacroCalories
  }

  public var carbsPercent: Double {
    guard totalMacroCalories > 0 else { return 0 }
    return carbsCalories / totalMacroCalories
  }

  public var fatPercent: Double {
    guard totalMacroCalories > 0 else { return 0 }
    return fatCalories / totalMacroCalories
  }
}

// MARK: - Chart Data Model

public struct MonthlyMacroChartData: Identifiable, Sendable, Equatable {
  public var id: Date { date }
  public let date: Date
  public let proteinPercent: Double
  public let carbsPercent: Double
  public let fatPercent: Double
  public let proteinGrams: Double
  public let carbsGrams: Double
  public let fatGrams: Double

  public init(
    date: Date,
    proteinPercent: Double,
    carbsPercent: Double,
    fatPercent: Double,
    proteinGrams: Double,
    carbsGrams: Double,
    fatGrams: Double
  ) {
    self.date = date
    self.proteinPercent = proteinPercent
    self.carbsPercent = carbsPercent
    self.fatPercent = fatPercent
    self.proteinGrams = proteinGrams
    self.carbsGrams = carbsGrams
    self.fatGrams = fatGrams
  }

  // MARK: - Stacked Chart Values (0-100 scale)

  public var proteinEnd: Double { proteinPercent * 100 }
  public var carbsEnd: Double { (proteinPercent + carbsPercent) * 100 }
  public var fatEnd: Double { (proteinPercent + carbsPercent + fatPercent) * 100 }

  // MARK: - Display Values

  public var proteinPercentDisplay: Int { Int(proteinPercent * 100) }
  public var carbsPercentDisplay: Int { Int(carbsPercent * 100) }
  public var fatPercentDisplay: Int { Int(fatPercent * 100) }
}

// MARK: - Chart Data Helpers

public extension YearInBloomNutritionStats {

  /// Monthly macro distribution data for stacked area chart
  func monthlyMacroChartData() -> [MonthlyMacroChartData] {
    monthlyMacroStats.compactMap { stat in
      guard stat.daysLogged > 0,
            let date = Calendar.current.date(
              from: DateComponents(year: year, month: stat.month, day: 15)
            ) else {
        return nil
      }
      return MonthlyMacroChartData(
        date: date,
        proteinPercent: stat.proteinPercent,
        carbsPercent: stat.carbsPercent,
        fatPercent: stat.fatPercent,
        proteinGrams: stat.averageProteinGrams,
        carbsGrams: stat.averageCarbsGrams,
        fatGrams: stat.averageFatGrams
      )
    }
  }
}

// MARK: - Preview

public extension YearInBloomNutritionStats {

  static var preview: YearInBloomNutritionStats {
    let monthlyStats = (1...12).map { month in
      MonthlyMacroStats(
        month: month,
        daysLogged: Int.random(in: 20...28),
        averageProteinGrams: Double.random(in: 100...150),
        averageCarbsGrams: Double.random(in: 200...300),
        averageFatGrams: Double.random(in: 60...90),
        averageCalories: Double.random(in: 1800...2200)
      )
    }

    return YearInBloomNutritionStats(
      year: 2024,
      monthlyMacroStats: monthlyStats,
      yearTotals: NutritionYearTotals(
        totalDaysLogged: 285,
        averageProteinGrams: 125,
        averageCarbsGrams: 250,
        averageFatGrams: 75,
        averageCalories: 2000
      ),
      generatedDate: .now
    )
  }
}
