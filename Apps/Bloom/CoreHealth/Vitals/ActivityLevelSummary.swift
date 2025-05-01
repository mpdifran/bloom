//
//  ActivityLevelSummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SFSafeSymbols
import SwiftUI
import DataContainer

public extension ActivityLevelSummary {
  enum ActivityLevel: String, CaseIterable, Identifiable {
    public var id: Self { self }

    case sedentary
    case light
    case moderate
    case high
    case intense

    public init(_ ratio: Double) {
      if ratio < 1.2 {
        self = .sedentary
      } else if ratio < 1.375 {
        self = .light
      } else if ratio < 1.55 {
        self = .moderate
      } else if ratio < 1.725 {
        self = .high
      } else {
        self = .intense
      }
    }
  }
}

public extension ActivityLevelSummary.ActivityLevel {

  var name: String {
    switch self {
    case .sedentary: "Sedentary"
    case .light: "Light"
    case .moderate: "Moderate"
    case .high: "High"
    case .intense: "Intense"
    }
  }

  var summary: String {
    switch self {
    case .sedentary: "Little to no exercise"
    case .light: "Exercise a couple times a week"
    case .moderate: "Exercise half the week"
    case .high: "Exercise almost every day"
    case .intense: "Intense exercise most days"
    }
  }

  var symbol: SFSymbol {
    switch self {
    case .sedentary: .figureStand
    case .light: .figureMixedCardio
    case .moderate: .figureRun
    case .high: .figureHighintensityIntervaltraining
    case .intense: .figureClimbing
    }
  }

  var color: Color {
    switch self {
    case .sedentary: .vitalWarning
    case .light, .moderate: .vitalGood
    case .high, .intense: .vitalGreat
    }
  }

  var barColor: Color {
    switch self {
    case .sedentary:
        .activityLevelSedentary
    case .light:
        .activityLevelLight
    case .moderate:
        .activityLevelModerate
    case .high:
        .activityLevelHigh
    case .intense:
        .activityLevelIntense
    }
  }

  var range: ClosedRange<Double> {
    switch self {
    case .sedentary:
      1...1.2
    case .light:
      1.2...1.375
    case .moderate:
      1.375...1.55
    case .high:
      1.55...1.725
    case .intense:
      1.725...2.5
    }
  }

  /// Multiply this value by the person's body weight in pounds to get their target calories.
  func calorieMultiplier(for healthTargetDetails: HealthTargetDetails) -> Double? {
    switch (self, healthTargetDetails.goal, healthTargetDetails.weightLossSpeed) {
    case (.sedentary, .loseWeight, .slow), (.light, .loseWeight, .slow):
      return 12
    case (.moderate, .loseWeight, .slow):
      return 14
    case (.high, .loseWeight, .slow), (.intense, .loseWeight, .slow):
      return 16
    case (.sedentary, .loseWeight, .moderate), (.light, .loseWeight, .moderate):
      return 11
    case (.moderate, .loseWeight, .moderate):
      return 13
    case (.high, .loseWeight, .moderate), (.intense, .loseWeight, .moderate):
      return 15
    case (.sedentary, .loseWeight, .fast), (.light, .loseWeight, .fast):
      return 10
    case (.moderate, .loseWeight, .fast):
      return 12
    case (.high, .loseWeight, .fast), (.intense, .loseWeight, .fast):
      return 14
    case (.sedentary, .maintainWeight, _), (.light, .maintainWeight, _):
      return 13
    case (.moderate, .maintainWeight, _):
      return 15
    case (.high, .maintainWeight, _), (.intense, .maintainWeight, _):
      return 17
    case (.sedentary, .gainWeight, _), (.light, .gainWeight, _):
      return 17
    case (.moderate, .gainWeight, _):
      return 19
    case (.high, .gainWeight, _), (.intense, .gainWeight, _):
      return 21
    default:
      return nil
    }
  }

  /// Multiply this by the person's BMR to get an estimate of their TDEE.
  var mifflinStJeorMultiplier: Double {
    switch self {
    case .sedentary: 1.2
    case .light: 1.375
    case .moderate: 1.55
    case .high: 1.725
    case .intense: 1.9
    }
  }
}

public struct ActivityLevelSummary: Hashable, Codable, Sendable {
  public let details: Details

  public init(details: Details) {
    self.details = details
  }
}

public extension ActivityLevelSummary {

  var barLevel: VitalModel.BarLevel? {
    guard
      let ratio = details.activityRatio,
      let level = details.activityLevel
    else { return nil }

    switch level {
    case .sedentary:
      let range = level.range
      return VitalModel.BarLevel(
        level: .medium,
        proportion: ratio.scaledPercent(lower: range.lowerBound, upper: range.upperBound)
      )
    case .light, .moderate:
      let lower = ActivityLevelSummary.ActivityLevel.light.range.lowerBound
      let upper = ActivityLevelSummary.ActivityLevel.moderate.range.upperBound
      return VitalModel.BarLevel(
        level: .high,
        proportion: ratio.scaledPercent(lower: lower, upper: upper)
      )
    case .high, .intense:
      let lower = ActivityLevelSummary.ActivityLevel.high.range.lowerBound
      let upper = ActivityLevelSummary.ActivityLevel.intense.range.upperBound
      return VitalModel.BarLevel(
        level: .optimal,
        proportion: ratio.scaledPercent(lower: lower, upper: upper)
      )
    }
  }

  var subtitle: String {
    let basal = details.averageBasalEnergyBurned
    let active = details.averageActiveEnergyBurned

    guard basal > 1 else { return "No Data" }

    return "\(String(format: "%.0f", basal)) Cal Basal\n\(String(format: "%.0f", active)) Cal Active"
  }
}

public extension ActivityLevelSummary {
  struct Details: Hashable, Codable, Sendable {
    public let averageBasalEnergyBurned: Double
    public let averageActiveEnergyBurned: Double
    public let energyRatioSamples: [DateValueSample]

    public init(
      averageBasalEnergyBurned: Double,
      averageActiveEnergyBurned: Double,
      energyRatioSamples: [DateValueSample]
    ) {
      self.averageBasalEnergyBurned = averageBasalEnergyBurned
      self.averageActiveEnergyBurned = averageActiveEnergyBurned
      self.energyRatioSamples = energyRatioSamples
    }
  }
}

public extension ActivityLevelSummary.Details {

  var activityRatio: Double? {
    guard averageBasalEnergyBurned > 1 else {
      return nil
    }
    return (averageActiveEnergyBurned + averageBasalEnergyBurned) / averageBasalEnergyBurned
  }

  var hasNoData: Bool {
    activityRatio == nil
  }

  var activityLevel: ActivityLevelSummary.ActivityLevel? {
    guard let ratio = activityRatio else { return nil }

    if ratio < 1.2 {
      return .sedentary
    } else if ratio < 1.375 {
      return .light
    } else if ratio < 1.55 {
      return .moderate
    } else if ratio < 1.725 {
      return .high
    } else {
      return .intense
    }
  }

  var hasSedentaryStreakLast3Days: Bool {
    guard let index = energyRatioSamples.lastIndex(where: { Calendar.current.isDateInYesterday($0.date) }) else {
      return false
    }

    guard
      let firstDay = energyRatioSamples.safeAccess(at: UInt(index - 2)),
      let secondDay = energyRatioSamples.safeAccess(at: UInt(index - 1)),
      let thirdDay = energyRatioSamples.safeAccess(at: UInt(index))
    else {
      return false
    }

    let firstLevel = ActivityLevelSummary.ActivityLevel(firstDay.value)
    let secondLevel = ActivityLevelSummary.ActivityLevel(secondDay.value)
    let thirdLevel = ActivityLevelSummary.ActivityLevel(thirdDay.value)

    return firstLevel == .sedentary && secondLevel == .sedentary && thirdLevel == .sedentary
  }

  var activityLevelRatioDistribution: [ActivityLevelSummary.ActivityLevel: Int] {
    var ratioDistribution = [ActivityLevelSummary.ActivityLevel: Int]()
    for sample in energyRatioSamples {
      for level in ActivityLevelSummary.ActivityLevel.allCases {
        if level.range.contains(sample.value) {
          ratioDistribution[level, default: 0] += 1
        }
      }
    }

    return ratioDistribution
  }
  
  func dayOfWeekActivityLevelRatioDistribution() -> [Int: Double] {
    var collection = [Int: [Double]]()
    for sample in energyRatioSamples {
      let dayOfWeek = Calendar.current.component(.weekday, from: sample.date)
      collection[dayOfWeek, default: []].append(sample.value)
    }

    var result = [Int: Double]()
    for key in collection.keys {
      result[key] = collection[key, default: []].average(keyPath: \.self)
    }

    return result
  }
}
