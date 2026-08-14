//
//  StressMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-25.
//

import SwiftUI
import DataContainer
import HealthKit
import BloomFoundation

private extension Double {
  static let hrvVariance: Double = 8
  static let rhrUpperThreadDiff: Double = 10
}

public extension StressMonthlySummary {
  enum Level {
    case relaxed
    case mild
    case moderate
    case high

    public init(score: Double) {
      if score < -0.5 {
        self = .high
      } else if score < 0 {
        self = .moderate
      } else if score < 0.5 {
        self = .mild
      } else {
        self = .relaxed
      }
    }

    public var name: String {
      switch self {
      case .relaxed: String(localized: "Relaxed", bundle: Bundle.coreHealth, comment: "Display name for stress monthly summary")
      case .mild: String(localized: "Mild", bundle: Bundle.coreHealth, comment: "Display name for stress monthly summary")
      case .moderate: String(localized: "Moderate", bundle: Bundle.coreHealth, comment: "Display name for stress monthly summary")
      case .high: String(localized: "High", bundle: Bundle.coreHealth, comment: "Display name for stress monthly summary")
      }
    }

    public var color: Color {
      switch self {
      case .relaxed: .vitalGreat
      case .mild: .vitalGood
      case .moderate: .vitalWarning
      case .high: .vitalSevere
      }
    }
  }
}

public struct StressMonthlySummary: Hashable, Sendable {
  public let details: Details
  public let lastMonthAverageSystolic: Double?
  public let lastMonthAverageDiastolic: Double?

  public init(
    details: Details,
    lastMonthAverageSystolic: Double?,
    lastMonthAverageDiastolic: Double?
  ) {
    self.details = details
    self.lastMonthAverageSystolic = lastMonthAverageSystolic
    self.lastMonthAverageDiastolic = lastMonthAverageDiastolic
  }

  public var score: Double {
    details.averageStressLevel?.scaledPercent(lower: -1, upper: 0.5) ?? 1
  }

  public var hasNoData: Bool {
    details.averageStressLevel == nil
  }

  public var barLevel: VitalModel.BarLevel? {
    guard
      let averageStressLevel = details.averageStressLevel,
      let level = details.level
    else { return nil }

    switch level {
    case .high:
      return VitalModel.BarLevel(
        level: .low,
        proportion: averageStressLevel.scaledPercent(lower: -1, upper: -0.5)
      )
    case .moderate:
      return VitalModel.BarLevel(
        level: .medium,
        proportion: averageStressLevel.scaledPercent(lower: -0.5, upper: 0)
      )
    case .mild:
      return VitalModel.BarLevel(
        level: .high,
        proportion: averageStressLevel.scaledPercent(lower: 0, upper: 0.5)
      )
    case .relaxed:
      return VitalModel.BarLevel(
        level: .optimal,
        proportion: averageStressLevel.scaledPercent(lower: 0.5, upper: 1)
      )
    }
  }
}

public extension StressMonthlySummary {
  struct Details: Hashable, Sendable {
    public let dateRange: DateRange
    public let heartRateVariability: [DateQuantitySample]
    public let twoMonthsHeartRateVariability: [DateQuantitySample]
    public let bloodPressureSystolic: [DateQuantitySample]
    public let twoMonthsBloodPressureSystolic: [DateQuantitySample]
    public let bloodPressureDiastolic: [DateQuantitySample]
    public let twoMonthsBloodPressureDiastolic: [DateQuantitySample]
    public let sleepAnalyses: [SleepAnalysis]

    public init(
      dateRange: DateRange,
      heartRateVariability: [DateQuantitySample],
      twoMonthsHeartRateVariability: [DateQuantitySample],
      bloodPressureSystolic: [DateQuantitySample],
      twoMonthsBloodPressureSystolic: [DateQuantitySample],
      bloodPressureDiastolic: [DateQuantitySample],
      twoMonthsBloodPressureDiastolic: [DateQuantitySample],
      sleepAnalyses: [SleepAnalysis]
    ) {
      self.dateRange = dateRange
      self.heartRateVariability = heartRateVariability
      self.twoMonthsHeartRateVariability = twoMonthsHeartRateVariability
      self.bloodPressureSystolic = bloodPressureSystolic
      self.twoMonthsBloodPressureSystolic = twoMonthsBloodPressureSystolic
      self.bloodPressureDiastolic = bloodPressureDiastolic
      self.twoMonthsBloodPressureDiastolic = twoMonthsBloodPressureDiastolic
      self.sleepAnalyses = sleepAnalyses

      self.calculateStressLevels()
    }

    private(set) public var averageHeartRateVariability: Double? = nil
    private(set) public var averageSystolic: Double? = nil
    private(set) public var averageDiastolic: Double? = nil
    private(set) public var averageSleepScore: Double? = nil
    private(set) public var stressLevels = [DateStressScore]()
    private(set) public var averageStressLevel: Double? = nil
    private(set) public var averageBloodPressureStressLevel: Double? = nil
    private(set) public var averageHeartRateVariabilityStressLevel: Double? = nil
    private(set) public var averageSleepStressLevel: Double? = nil
  }

  struct DateStressScore: Hashable, Sendable, Identifiable {
    public var id: Date { date }
    public let date: Date
    public let stressScore: Double
    public let bloodPressureStressScore: Double
    public let hrvStressScore: Double
    public let sleepStressScore: Double

    public init(
      date: Date,
      stressScore: Double,
      bloodPressureStressScore: Double,
      hrvStressScore: Double,
      sleepStressScore: Double
    ) {
      self.date = date
      self.stressScore = stressScore
      self.bloodPressureStressScore = bloodPressureStressScore
      self.hrvStressScore = hrvStressScore
      self.sleepStressScore = sleepStressScore
    }

    public var level: StressMonthlySummary.Level {
      StressMonthlySummary.Level(score: stressScore)
    }

    public var bloodPressureLevel: StressMonthlySummary.Level {
      StressMonthlySummary.Level(score: bloodPressureStressScore)
    }

    public var hrvLevel: StressMonthlySummary.Level {
      StressMonthlySummary.Level(score: hrvStressScore)
    }

    public var sleepLevel: StressMonthlySummary.Level {
      StressMonthlySummary.Level(score: sleepStressScore)
    }
  }
}

public extension StressMonthlySummary.Details {

  mutating func calculateStressLevels() {
    let targetDateRange = DateRange.trailingMonths(from: dateRange.end, numberOfMonths: 1)

    var stressScores = [StressMonthlySummary.DateStressScore]()

    let hrvValues = twoMonthsHeartRateVariability.map({ $0.quantity.doubleValue(for: .millisecond()) })
    let hrvAverage = hrvValues.average(keyPath: \.self)
    let hrvStdDev = hrvValues.standardDeviation(keyPath: \.self, mean: hrvAverage)

    Calendar.current.iterate(dateRange: targetDateRange, by: DateComponents(day: 1)) { date in
      let referenceDate = Calendar.current.startOfDay(for: date)

      let hrvStressScore = simplifiedHVRStressLevel(
        for: referenceDate,
        average: hrvAverage,
        standardDeviation: hrvStdDev
      )
      let bloodPressureScore = bloodPressureStressLevel(for: referenceDate)
      let sleepStressScore = sleepStressLevel(for: referenceDate)

      let allStressScores = [
        hrvStressScore,
        bloodPressureScore,
        sleepStressScore
      ].unwrap()

      //            print("STRESS DEBUG \(referenceDate) HRV: \(hrvStressScore), RHR: \(rhrStressScore), BP: \(bloodPressureScore), SLEEP: \(sleepStressScore)")

      if allStressScores.isNotEmpty {
        stressScores.append(
          StressMonthlySummary.DateStressScore(
            date: referenceDate,
            stressScore: allStressScores.average(keyPath: \.self),
            bloodPressureStressScore: bloodPressureScore ?? 0,
            hrvStressScore: hrvStressScore ?? 0,
            sleepStressScore: sleepStressScore ?? 0
          )
        )
      }
    }

    if heartRateVariability.isNotEmpty {
      self.averageHeartRateVariability = heartRateVariability.map({ $0.quantity.doubleValue(for: .millisecond()) }).average(keyPath: \.self)
    }
    if bloodPressureSystolic.isNotEmpty {
      self.averageSystolic = bloodPressureSystolic.map({ $0.quantity.doubleValue(for: .millimeterOfMercury()) }).average(keyPath: \.self)
    }
    if bloodPressureDiastolic.isNotEmpty {
      self.averageDiastolic = bloodPressureDiastolic.map({ $0.quantity.doubleValue(for: .millimeterOfMercury()) }).average(keyPath: \.self)
    }
    if sleepAnalyses.isNotEmpty {
      self.averageSleepScore = sleepAnalyses.average(keyPath: \.overallScoreDouble)
    }

    self.stressLevels = stressScores
    if stressScores.isNotEmpty {
      self.averageStressLevel = stressScores.average(keyPath: \.stressScore)
      self.averageBloodPressureStressLevel = stressScores.average(keyPath: \.bloodPressureStressScore)
      self.averageHeartRateVariabilityStressLevel = stressScores.average(keyPath: \.hrvStressScore)
      self.averageSleepStressLevel = stressScores.average(keyPath: \.sleepStressScore)
    }
  }

  func simplifiedHVRStressLevel(
    for date: Date,
    average: Double,
    standardDeviation: Double?
  ) -> Double? {
    guard
      let standardDeviation,
      let currentSample = twoMonthsHeartRateVariability.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
    else { return nil }

    let value = currentSample.quantity.doubleValue(for: .millisecond())
    let lower = average - 2 * standardDeviation
    let upper = average + 2 * standardDeviation

    return value.scaledSymmetricalScore(lower: lower, upper: upper)
  }

  func bloodPressureStressLevel(for date: Date) -> Double? {
    let trailingDateRange = DateRange.trailingMonths(from: date, numberOfMonths: 1)

    let trailingSystolicValues = twoMonthsBloodPressureSystolic.compactMap { (sample) -> Double? in
      guard trailingDateRange.contains(date: sample.date) else { return nil }

      return sample.quantity.doubleValue(for: .millimeterOfMercury())
    }

    let trailingDiastolicValues = twoMonthsBloodPressureDiastolic.compactMap { (sample) -> Double? in
      guard trailingDateRange.contains(date: sample.date) else { return nil }

      return sample.quantity.doubleValue(for: .millimeterOfMercury())
    }

    guard trailingSystolicValues.isNotEmpty, trailingDiastolicValues.isNotEmpty else { return nil }

    let bloodPressureStressScore = bloodPressureStressScore(
      systolic: trailingSystolicValues.average(keyPath: \.self),
      diastolic: trailingDiastolicValues.average(keyPath: \.self)
    )

    return bloodPressureStressScore
  }

  func bloodPressureStressScore(systolic: Double , diastolic: Double) -> Double {
    let systolicScore: Double
    if systolic <= 90 {
      systolicScore = systolic.scaledPercent(lower: 90, upper: 70)
    } else if systolic <= 120 {
      systolicScore = 0
    } else {
      systolicScore = (1 - systolic.scaledPercent(lower: 180, upper: 120)) * -1
    }

    let diastolicScore: Double
    if diastolic <= 60 {
      diastolicScore = diastolic.scaledPercent(lower: 60, upper: 40)
    } else if diastolic <= 80 {
      diastolicScore = 0
    } else {
      diastolicScore = (1 - diastolic.scaledPercent(lower: 110, upper: 80)) * -1
    }

    return [systolicScore, diastolicScore].average(keyPath: \.self)
  }

  func sleepStressLevel(for date: Date) -> Double? {
    guard
      let sleepAnalysis = sleepAnalyses.first(where: { Calendar.current.isDate($0.endDate, inSameDayAs: date) })
    else { return nil }

    let score = sleepAnalysis.overallScoreDouble.scaledSymmetricalScore(lower: 50, upper: 100)

    //        print("SLEEP STRESS DEBUG \(sleepAnalysis.endDate) Sleep score: \(sleepAnalysis.overallScoreDouble.format(using: .oneDecimalPlace)) Score: \(score.format(using: .twoDecimalPlaces))")

    return score
  }

  var subtitle: String? {
    let hrv: String?
    if heartRateVariability.isNotEmpty {
      let average = heartRateVariability.map({ $0.quantity.doubleValue(for: .millisecond()) }).average(keyPath: \.self)
      hrv = "HRV: \(average.format()) ms"
    } else {
      hrv = nil
    }

    let bloodPressure: String?
    if bloodPressureSystolic.isNotEmpty, bloodPressureDiastolic.isNotEmpty {
      let systolicAverage = bloodPressureSystolic.map({ $0.quantity.doubleValue(for: .millimeterOfMercury()) }).average(keyPath: \.self)
      let diastolicAverage = bloodPressureDiastolic.map({ $0.quantity.doubleValue(for: .millimeterOfMercury()) }).average(keyPath: \.self)
      bloodPressure = "BP: \(systolicAverage.format())/\(diastolicAverage.format()) mmHg"
    } else {
      bloodPressure = nil
    }

    let compactEntries = [hrv, bloodPressure].compactMap({ $0 })

    guard compactEntries.isNotEmpty else { return nil }

    return compactEntries.joined(separator: "\n")
  }

  var level: StressMonthlySummary.Level? {
    guard let averageStressLevel else { return nil }

    return StressMonthlySummary.Level(score: averageStressLevel)
  }
}
