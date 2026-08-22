//
//  HeartHealthMonthlySummary.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-07-24.
//

import SwiftUI
import DataContainer
import HealthKit

public extension Double {
  static let maxHeartRateRecovery: Double = 18
  static let minHeartRateRecovery: Double = 10
}

public extension HeartHealthMonthlySummary {
  enum HeartHealthLevel {
    case atRisk
    case moderate // Could be fair
    case healthy
    case optimal

    public var name: String {
      switch self {
      case .atRisk: String(localized: "At Risk", bundle: Bundle.coreHealth, comment: "Display name for heart health monthly summary")
      case .moderate: String(localized: "Moderate", bundle: Bundle.coreHealth, comment: "Display name for heart health monthly summary")
      case .healthy: String(localized: "Healthy", bundle: Bundle.coreHealth, comment: "Display name for heart health monthly summary")
      case .optimal: String(localized: "Optimal", bundle: Bundle.coreHealth, comment: "Display name for heart health monthly summary")
      }
    }

    public var color: Color {
      switch self {
      case .atRisk: .vitalSevere
      case .moderate: .vitalWarning
      case .healthy: .vitalGood
      case .optimal: .vitalGreat
      }
    }
  }

  enum CardioFitnessLevel {
    case low
    case belowAverage
    case aboveAverage
    case high

    public var name: String {
      switch self {
      case .low: String(localized: "Poor", bundle: Bundle.coreHealth, comment: "Display name for heart health monthly summary")
      case .belowAverage: String(localized: "Fair", bundle: Bundle.coreHealth, comment: "Display name for heart health monthly summary")
      case .aboveAverage: String(localized: "Good", bundle: Bundle.coreHealth, comment: "Display name for heart health monthly summary")
      case .high: String(localized: "Excellent", bundle: Bundle.coreHealth, comment: "Display name for heart health monthly summary")
      }
    }

    public var color: Color {
      switch self {
      case .low: .vitalSevere
      case .belowAverage: .vitalWarning
      case .aboveAverage: .vitalGood
      case .high: .vitalGreat
      }
    }

    public var summary: String {
      switch self {
      case .low:
        String(localized: "This level indicates poor cardiovascular fitness and is associated with a higher risk of cardiovascular diseases and other health issues.", bundle: Bundle.coreHealth, comment: "Summary for heart health monthly summary")
      case .belowAverage:
        String(localized: "Individuals in this category have cardiovascular fitness below the median but are not in the lowest fitness category.", bundle: Bundle.coreHealth, comment: "Summary for heart health monthly summary")
      case .aboveAverage:
        String(localized: "This level represents better-than-average cardiovascular fitness and suggests a lower risk of cardiovascular diseases.", bundle: Bundle.coreHealth, comment: "Summary for heart health monthly summary")
      case .high:
        String(localized: "This top level is characterized by superior cardiovascular fitness, often indicating excellent overall health and a lower risk of heart-related conditions.", bundle: Bundle.coreHealth, comment: "Summary for heart health monthly summary")
      }
    }
  }
}

// TODO: Incorporate resting heart rate
public struct HeartHealthMonthlySummary: Hashable, Sendable {
  public let details: Details
  public let lastMonthDetails: Details

  public init(details: Details, lastMonthDetails: Details) {
    self.details = details
    self.lastMonthDetails = lastMonthDetails
  }
}

public extension HeartHealthMonthlySummary {
  struct Details: Hashable, Sendable {
    public let averageVO2Max: HKQuantity?
    public let averageHeartRateRecovery: HKQuantity?
    public let averageRestingHeartRate: HKQuantity?

    public init(
      averageVO2Max: HKQuantity?,
      averageHeartRateRecovery: HKQuantity?,
      averageRestingHeartRate: HKQuantity?
    ) {
      self.averageVO2Max = averageVO2Max
      self.averageHeartRateRecovery = averageHeartRateRecovery
      self.averageRestingHeartRate = averageRestingHeartRate
    }
  }
}

public extension HeartHealthMonthlySummary.Details {

  var score: Double? {
    let scores = [
      vo2MaxScore,
      heartRateRecoveryScore,
      restingHeartRateScore
    ].unwrap()

    if scores.isEmpty { return nil }

    return scores.average(keyPath: \.self)
  }

  var hasNoData: Bool {
    vo2MaxScore == nil && heartRateRecoveryScore == nil && restingHeartRateScore == nil
  }

  var barLevel: VitalModel.BarLevel? {
    guard let level, let score else { return nil }

    switch level {
    case .atRisk:
      return VitalModel.BarLevel(
        level: .low,
        proportion: score.scaledPercent(lower: 0, upper: 0.4)
      )
    case .moderate:
      return VitalModel.BarLevel(
        level: .medium,
        proportion: score.scaledPercent(lower: 0.4, upper: 0.7)
      )
    case .healthy:
      return VitalModel.BarLevel(
        level: .high,
        proportion: score.scaledPercent(lower: 0.7, upper: 0.95)
      )
    case .optimal:
      return VitalModel.BarLevel(
        level: .optimal,
        proportion: score.scaledPercent(lower: 0.95, upper: 1)
      )
    }
  }

  var level: HeartHealthMonthlySummary.HeartHealthLevel? {
    guard let score else { return nil }

    // TODO: Vet these scores
    if score > 0.95 {
      return .optimal
    } else if score > 0.7 {
      return .healthy
    } else if score > 0.4 {
      return .moderate
    } else {
      return .atRisk
    }
  }

  var cardioFitnessLevel: HeartHealthMonthlySummary.CardioFitnessLevel? {
    guard let goal = HealthGoalProvider.shared.goalVO2MaxForUser(), let averageVO2Max else { return nil }

    let vo2Max = averageVO2Max.doubleValue(for: .vo2Max())

    if vo2Max < goal.2 {
      return .low
    } else if vo2Max < goal.1 {
      return .belowAverage
    } else if vo2Max < goal.0 {
      return .aboveAverage
    } else {
      return .high
    }
  }

  @MainActor
  var subtitle: String? {
    let vo2Max = averageVO2Max.map { quantity in
      let value = quantity.displayString(for: .vo2Max())
      return String(
        localized: "VO₂ Max: \(value)",
        bundle: Bundle.coreHealth,
        comment: "Heart health subtitle line. The placeholder is a VO₂ max value."
      )
    }
    let rhr = averageRestingHeartRate.map { _ in
      let value = displayRestingHeartRate
      return String(
        localized: "RHR: \(value)",
        bundle: Bundle.coreHealth,
        comment: "Heart health subtitle line. RHR is resting heart rate; the placeholder is the value in bpm."
      )
    }
    let heartRateRecovery = averageHeartRateRecovery.map { _ in
      let value = displayHeartRateRecovery
      return String(
        localized: "HRR: \(value)",
        bundle: Bundle.coreHealth,
        comment: "Heart health subtitle line. HRR is heart rate recovery; the placeholder is the value in bpm."
      )
    }

    let descriptions = [vo2Max, rhr, heartRateRecovery].unwrap()

    if descriptions.isEmpty {
      return nil
    }
    return descriptions.joined(separator: "\n")
  }

  var displayHeartRateRecovery: String {
    guard let averageHeartRateRecovery else { return "" }
    return "\(averageHeartRateRecovery.doubleValue(for: .bpm()).format()) bpm"
  }

  var displayRestingHeartRate: String {
    guard let averageRestingHeartRate else { return "" }
    return "\(averageRestingHeartRate.doubleValue(for: .bpm()).format()) bpm"
  }
}

private extension HeartHealthMonthlySummary.Details {

  var vo2MaxScore: Double? {
    if let goal = HealthGoalProvider.shared.goalVO2MaxForUser() {
      return averageVO2Max?.doubleValue(for: .vo2Max()).scaledPercent(lower: goal.2, upper: goal.1)
    }
    return nil
  }

  var heartRateRecoveryScore: Double? {
    averageHeartRateRecovery?.doubleValue(for: .bpm()).scaledPercent(
      lower: .minHeartRateRecovery,
      upper: .maxHeartRateRecovery
    )
  }

  var restingHeartRateScore: Double? {
    let (_, max) = HealthGoalProvider.shared.goalRestingHeartRateForUser()

    return averageRestingHeartRate?.doubleValue(for: .bpm()).scaledPercent(lower: max + 10, upper: max)
  }
}
