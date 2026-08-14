//
//  BodyCompositionMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI
import HealthKit
import DataContainer

public extension BodyCompositionMonthlySummary {
  enum PercentageRange {
    case unknown
    case essentialFat
    case athlete
    case fit
    case healthy
    case high

    public var name: String {
      switch self {
      case .unknown: String(localized: "Unknown", bundle: Bundle.coreHealth, comment: "Display name for body composition monthly summary")
      case .essentialFat: String(localized: "Essential Fat", bundle: Bundle.coreHealth, comment: "Display name for body composition monthly summary")
      case .athlete: String(localized: "Athlete", bundle: Bundle.coreHealth, comment: "Display name for body composition monthly summary")
      case .fit: String(localized: "Fit", bundle: Bundle.coreHealth, comment: "Display name for body composition monthly summary")
      case .healthy: String(localized: "Healthy", bundle: Bundle.coreHealth, comment: "Display name for body composition monthly summary")
      case .high: String(localized: "High", bundle: Bundle.coreHealth, comment: "Display name for body composition monthly summary")
      }
    }

    public var color: Color {
      switch self {
      case .unknown: .gray
      case .athlete, .fit: .vitalGreat
      case .healthy: .vitalGood
      case .essentialFat: .vitalWarning
      case .high: .vitalSevere
      }
    }

    public func rangeDescription(from goals: BodyFatPercentageGoalThresholds) -> String {
      guard let values = rangeValues(from: goals) else { return "" }

      return "\(values.lowerBound.formatted(.percent)) - \(values.upperBound.formatted(.percent))"
    }

    public func rangeValues(from goals: BodyFatPercentageGoalThresholds) -> ClosedRange<Double>? {
      switch self {
      case .unknown:
        nil
      case .essentialFat:
        0...goals.maxEssentialFat
      case .athlete:
        goals.maxEssentialFat...goals.maxAthleteFat
      case .fit:
        goals.maxAthleteFat...goals.maxFitFat
      case .healthy:
        goals.maxFitFat...goals.maxHealthyFat
      case .high:
        goals.maxHealthyFat...1
      }
    }
  }
}

public struct BodyCompositionMonthlySummary: Hashable, Sendable {
  public let details: Details
  public let lastMonthDetails: Details

  public init(details: Details, lastMonthDetails: Details) {
    self.details = details
    self.lastMonthDetails = lastMonthDetails
  }
}

public extension BodyCompositionMonthlySummary {

  var score: Double {
    details.score ?? 1
  }

  var barLevel: VitalModel.BarLevel? {
    guard let range = details.range,
          let goal = details.goalBodyFatPercentage,
          let bodyFatPercentage = details.bodyFatPercentage
    else { return nil }

    let bodyFat = bodyFatPercentage.doubleValue(for: .percent())

    switch range {
    case .unknown:
      return nil
    case .essentialFat:
      return VitalModel.BarLevel(
        level: .medium,
        proportion: bodyFat.scaledPercent(lower: 0, upper: goal.maxEssentialFat)
      )
    case .athlete, .fit:
      return VitalModel.BarLevel(
        level: .optimal,
        proportion: bodyFat.scaledPercent(lower: goal.maxFitFat, upper: goal.maxEssentialFat)
      )
    case .healthy:
      return VitalModel.BarLevel(
        level: .high,
        proportion: bodyFat.scaledPercent(lower: goal.maxHealthyFat, upper: goal.maxFitFat)
      )
    case .high:
      return VitalModel.BarLevel(
        level: .low,
        proportion: bodyFat.scaledPercent(lower: goal.maxHighFat, upper: goal.maxHealthyFat)
      )
    }
  }

  @MainActor
  var subtitle: String? {
    var entries = [String]()

    if let bodyWeight = details.averageBodyMass {
      entries.append("Avg Weight: \(bodyWeight.displayString(for: .pound(), formatter: .oneDecimalPlace))")
    }
    if let bodyFatPercentage = details.bodyFatPercentage?.doubleValue(for: .percent()) {
      let percent = bodyFatPercentage * 100
      entries.append("Fat: \(percent.format())%")
    }

    let compactEntries = entries.compactMap({ $0 })

    guard compactEntries.isNotEmpty else { return nil }

    return compactEntries.joined(separator: "\n")
  }

  var bodyMassTrendDescription: String? {
    guard
      let thisMonth = details.averageBodyMass?.doubleValue(for: .pound()),
      let lastMonth = lastMonthDetails.averageBodyMass?.doubleValue(for: .pound())
    else { return nil }

    let difference = abs(thisMonth - lastMonth)

    if difference < 1 {
      return "Your average body weight has held steady over this month compared to last month."
    }

    if thisMonth > lastMonth {
      let formattedPercent = ((thisMonth - lastMonth) / lastMonth * 100).format(using: .oneDecimalPlace)
      return "Your average body weight has increased \(formattedPercent)% this month."
    } else {
      let formattedPercent = ((lastMonth - thisMonth) / lastMonth * 100).format(using: .oneDecimalPlace)
      return "Your average body weight has decreased \(formattedPercent)% this month."
    }
  }
}

public extension BodyCompositionMonthlySummary {
  struct Details: Hashable, Sendable {
    public let bodyFatPercentage: HKQuantity?
    public let goalBodyFatPercentage: BodyFatPercentageGoalThresholds?
    public let averageBodyMass: HKQuantity?

    public init(
      bodyFatPercentage: HKQuantity?,
      goalBodyFatPercentage: BodyFatPercentageGoalThresholds?,
      averageBodyMass: HKQuantity?
    ) {
      self.bodyFatPercentage = bodyFatPercentage
      self.goalBodyFatPercentage = goalBodyFatPercentage
      self.averageBodyMass = averageBodyMass
    }
  }
}

public extension BodyCompositionMonthlySummary.Details {

  var score: Double? {
    guard
      let goal = goalBodyFatPercentage,
      let bodyFatPercentage
    else { return nil }

    return bodyFatPercentage.doubleValue(for: .percent()).scaledPercent(lower: goal.maxHighFat, upper: goal.maxHealthyFat)
  }

  var hasNoData: Bool {
    bodyFatPercentage == nil && averageBodyMass == nil
  }

  var range: BodyCompositionMonthlySummary.PercentageRange? {
    guard
      let goal = goalBodyFatPercentage,
      let bodyFatPercentage
    else {
      if averageBodyMass == nil {
        return nil
      }
      return .unknown
    }

    let percent = bodyFatPercentage.doubleValue(for: .percent())

    if percent < goal.maxEssentialFat {
      return .essentialFat
    } else if percent < goal.maxAthleteFat {
      return .athlete
    } else if percent < goal.maxFitFat {
      return .fit
    } else if percent < goal.maxHealthyFat {
      return .healthy
    } else {
      return .high
    }
  }
}
