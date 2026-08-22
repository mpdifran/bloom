//
//  BiologicalAgeTypes.swift
//  CoreHealth
//
//  Created by Mark DiFranco on 2026-01-25.
//

import Foundation
import SwiftUI
import BloomFoundation

// MARK: - BiologicalAgeConfidence

public enum BiologicalAgeConfidence: String, Sendable, Codable {
  case high
  case moderate
  case low

  public var displayName: String {
    switch self {
    case .high: String(localized: "High Confidence", bundle: Bundle.coreHealth, comment: "Display name for biological age confidence")
    case .moderate: String(localized: "Moderate Confidence", bundle: Bundle.coreHealth, comment: "Display name for biological age confidence")
    case .low: String(localized: "Low Confidence", bundle: Bundle.coreHealth, comment: "Display name for biological age confidence")
    }
  }

  public var description: String {
    switch self {
    case .high:
      String(localized: "Your biological age is calculated using most of your available health metrics.", bundle: Bundle.coreHealth, comment: "Description for biological age confidence")
    case .moderate:
      String(localized: "Your biological age is based on a moderate amount of health data. Adding more metrics will improve accuracy.", bundle: Bundle.coreHealth, comment: "Description for biological age confidence")
    case .low:
      String(localized: "Limited health data is available. Track more health metrics to get a more accurate biological age.", bundle: Bundle.coreHealth, comment: "Description for biological age confidence")
    }
  }

  public var color: Color {
    switch self {
    case .high: .mutedGreen
    case .moderate: .mutedYellow
    case .low: .secondary
    }
  }
}

// MARK: - BiologicalAgeResult

public struct BiologicalAgeResult: Sendable, Codable {
  public let biologicalAge: Double
  public let actualAge: Double
  public let lastCalculated: Date
  public var metricContributions: [MetricContribution]?

  public init(
    biologicalAge: Double,
    actualAge: Double,
    lastCalculated: Date,
    metricContributions: [MetricContribution]? = nil
  ) {
    self.biologicalAge = biologicalAge
    self.actualAge = actualAge
    self.lastCalculated = lastCalculated
    self.metricContributions = metricContributions
  }

  public var ageDelta: Double {
    biologicalAge - actualAge
  }

  public var isYounger: Bool {
    biologicalAge < actualAge
  }

  /// The percentage of available health metrics by weight (0-100)
  public var availableWeightPercentage: Double {
    let totalWeight = metricContributions?.reduce(0.0) { $0 + $1.weight } ?? 0
    return min(totalWeight * 100, 100)
  }

  /// The confidence level based on available metric weight coverage
  public var confidence: BiologicalAgeConfidence {
    let percentage = availableWeightPercentage
    if percentage > 80 { return .high }
    if percentage > 50 { return .moderate }
    return .low
  }
}

// MARK: - MetricContribution

public struct MetricContribution: Sendable, Identifiable, Codable {
  public var id: BiologicalAgeMetric { metric }
  public let metric: BiologicalAgeMetric
  public let rawValue: Double
  public let equivalentAge: Double?
  public let ageDelta: Double
  public let weight: Double
  public let weightedDelta: Double

  public init(
    metric: BiologicalAgeMetric,
    rawValue: Double,
    equivalentAge: Double?,
    ageDelta: Double,
    weight: Double,
    weightedDelta: Double
  ) {
    self.metric = metric
    self.rawValue = rawValue
    self.equivalentAge = equivalentAge
    self.ageDelta = ageDelta
    self.weight = weight
    self.weightedDelta = weightedDelta
  }
}

// MARK: - BiologicalAgeMetric

public enum BiologicalAgeMetric: String, Sendable, CaseIterable, Codable {
  case vo2Max = "VO₂ Max"
  case restingHeartRate = "Resting Heart Rate"
  case heartRateRecovery = "Heart Rate Recovery"
  case hrvTrend = "HRV Trend"
  case heartRateReserve = "Heart Rate Reserve"
  case zoneMinutes = "Zone Minutes"
  case activityLevel = "Activity Level"
  case walkingSpeed = "Walking Speed"
  case stairClimbSpeed = "Stair Climb Speed"
  case sleepScore = "Sleep Score"
  case sleepDurationVariability = "Sleep Variability"
  case bedtimeConsistency = "Bedtime Consistency"
  case sleepHeartRate = "Sleep Heart Rate"
  case sleepRespiratoryRate = "Respiratory Rate"
  case bodyFatPercentage = "Body Fat %"
  case bloodPressure = "Blood Pressure"
  case smoking = "Smoking"
  case alcohol = "Alcohol"

  /// The user-facing name. `rawValue` stays canonical English — it is a backend payload key.
  public var displayName: String {
    switch self {
    case .vo2Max: String(localized: "VO₂ Max", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .restingHeartRate: String(localized: "Resting Heart Rate", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .heartRateRecovery: String(localized: "Heart Rate Recovery", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .hrvTrend: String(localized: "HRV Trend", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .heartRateReserve: String(localized: "Heart Rate Reserve", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .zoneMinutes: String(localized: "Zone Minutes", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .activityLevel: String(localized: "Activity Level", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .walkingSpeed: String(localized: "Walking Speed", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .stairClimbSpeed: String(localized: "Stair Climb Speed", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .sleepScore: String(localized: "Sleep Score", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .sleepDurationVariability: String(localized: "Sleep Variability", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .bedtimeConsistency: String(localized: "Bedtime Consistency", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .sleepHeartRate: String(localized: "Sleep Heart Rate", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .sleepRespiratoryRate: String(localized: "Respiratory Rate", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .bodyFatPercentage: String(localized: "Body Fat %", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .bloodPressure: String(localized: "Blood Pressure", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .smoking: String(localized: "Smoking", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    case .alcohol: String(localized: "Alcohol", bundle: Bundle.coreHealth, comment: "Display name for biological age metric")
    }
  }

  public var weight: Double {
    switch self {
    case .vo2Max: 0.18
    case .restingHeartRate: 0.06
    case .heartRateRecovery: 0.04
    case .hrvTrend: 0.06
    case .heartRateReserve: 0.04
    case .zoneMinutes: 0.07
    case .activityLevel: 0.06
    case .walkingSpeed: 0.03
    case .stairClimbSpeed: 0.03
    case .sleepScore: 0.07
    case .sleepDurationVariability: 0.04
    case .bedtimeConsistency: 0.03
    case .sleepHeartRate: 0.03
    case .sleepRespiratoryRate: 0.02
    case .bodyFatPercentage: 0.06
    case .bloodPressure: 0.08
    case .smoking: 0.07
    case .alcohol: 0.03
    }
  }

  public var category: BiologicalAgeCategory {
    switch self {
    case .vo2Max, .restingHeartRate, .heartRateRecovery, .hrvTrend, .heartRateReserve:
      return .cardiorespiratory
    case .zoneMinutes, .activityLevel, .walkingSpeed, .stairClimbSpeed:
      return .activity
    case .sleepScore, .sleepDurationVariability, .bedtimeConsistency, .sleepHeartRate, .sleepRespiratoryRate:
      return .sleep
    case .bodyFatPercentage, .bloodPressure:
      return .bodyComposition
    case .smoking, .alcohol:
      return .lifestyle
    }
  }
}

// MARK: - BiologicalAgeCategory

public enum BiologicalAgeCategory: String, Sendable, CaseIterable {
  case cardiorespiratory = "Cardiorespiratory"
  case activity = "Activity"
  case sleep = "Sleep"
  case bodyComposition = "Body Composition"
  case lifestyle = "Lifestyle"

  /// The user-facing name. `rawValue` stays canonical English — it is a backend payload key.
  public var displayName: String {
    switch self {
    case .cardiorespiratory: String(localized: "Cardiorespiratory", bundle: Bundle.coreHealth, comment: "Display name for biological age category")
    case .activity: String(localized: "Activity", bundle: Bundle.coreHealth, comment: "Display name for biological age category")
    case .sleep: String(localized: "Sleep", bundle: Bundle.coreHealth, comment: "Display name for biological age category")
    case .bodyComposition: String(localized: "Body Composition", bundle: Bundle.coreHealth, comment: "Display name for biological age category")
    case .lifestyle: String(localized: "Lifestyle", bundle: Bundle.coreHealth, comment: "Display name for biological age category")
    }
  }
}
