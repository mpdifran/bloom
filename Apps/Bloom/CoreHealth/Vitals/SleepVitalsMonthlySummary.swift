//
//  SleepVitalsMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI
import DataContainer

public extension SleepVitalsMonthlySummary {
  enum SleepQuality: CaseIterable {
    case poor
    case low
    case good
    case great

    public init(sleepScore: Double) {
      if sleepScore < 4 {
        self = .poor
      } else if sleepScore < 7 {
        self = .low
      } else if sleepScore < 9 {
        self = .good
      } else {
        self = .great
      }
    }

    public var name: String {
      switch self {
      case .poor: "Poor"
      case .low: "Low"
      case .good: "Good"
      case .great: "Great"
      }
    }

    public var color: Color {
      switch self {
      case .poor: .vitalSevere
      case .low: .vitalWarning
      case .good: .vitalGood
      case .great: .vitalGreat
      }
    }
  }
}

public struct SleepVitalsMonthlySummary: Hashable, Codable, Sendable {
  public let details: Details

  public init(details: Details) {
    self.details = details
  }
}

public extension SleepVitalsMonthlySummary {

  var score: Double {
    details.score ?? 1
  }

  var barLevel: VitalModel.BarLevel? {
    guard
      let averageSleepScore = details.averageSleepScore,
      let level = details.quality
    else { return nil }

    switch level {
    case .poor:
      return VitalModel.BarLevel(
        level: .low,
        proportion: averageSleepScore.scaledPercent(lower: 0, upper: 4)
      )
    case .low:
      return VitalModel.BarLevel(
        level: .medium,
        proportion: averageSleepScore.scaledPercent(lower: 4, upper: 7)
      )
    case .good:
      return VitalModel.BarLevel(
        level: .high,
        proportion: averageSleepScore.scaledPercent(lower: 7, upper: 9)
      )
    case .great:
      return VitalModel.BarLevel(
        level: .optimal,
        proportion: averageSleepScore.scaledPercent(lower: 9, upper: 10)
      )
    }
  }

  var subtitleText: String? {
    var entries = [String?]()

    if
      let averageSleepLength = details.averageSleepLength,
      let formattedDuration = DateFormatter.timeIntervalHourMinuteShort.string(from: DateComponents(minute: Int(averageSleepLength)))
    {
      entries.append("Avg: \(formattedDuration)")
    }

    if let averageREMSleepPercent = details.averageREMSleepPercent {
      entries.append("REM: \(String(format: "%.0f", averageREMSleepPercent * 100))%")
    }
    if let averageDeepSleepPercent = details.averageDeepSleepPercent {
      entries.append("Deep: \(String(format: "%.0f", averageDeepSleepPercent * 100))%")
    }

    let nonNilEntries = entries.compactMap({ $0 })

    guard nonNilEntries.isNotEmpty else { return nil }

    return nonNilEntries.joined(separator: "\n")
  }
}

public extension SleepVitalsMonthlySummary {
  struct Details: Hashable, Codable, Sendable {
    public let averageREMSleepPercent: Double?
    public let averageCoreSleepPercent: Double?
    public let averageDeepSleepPercent: Double?
    public let averageAwakeSleepPercent: Double?
    public let averageSleepLength: Double?
    public let averageSleepScore: Double?

    public init(
      averageREMSleepPercent: Double?,
      averageCoreSleepPercent: Double?,
      averageDeepSleepPercent: Double?,
      averageAwakeSleepPercent: Double?,
      averageSleepLength: Double?,
      averageSleepScore: Double?
    ) {
      self.averageREMSleepPercent = averageREMSleepPercent
      self.averageCoreSleepPercent = averageCoreSleepPercent
      self.averageDeepSleepPercent = averageDeepSleepPercent
      self.averageAwakeSleepPercent = averageAwakeSleepPercent
      self.averageSleepLength = averageSleepLength
      self.averageSleepScore = averageSleepScore
    }
  }
}

public extension SleepVitalsMonthlySummary.Details {

  var score: Double? {
    averageSleepScore?.scaledPercent(lower: 4, upper: 8)
  }

  var hasNoData: Bool {
    averageSleepScore == nil
  }

  var quality: SleepVitalsMonthlySummary.SleepQuality? {
    guard let averageSleepScore else { return nil }

    return SleepVitalsMonthlySummary.SleepQuality(sleepScore: averageSleepScore)
  }
}
