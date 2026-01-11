//
//  MonitorMetricType.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import HealthKit
import SFSafeSymbols

/// Defines the health metrics tracked by the Monitor feature.
/// Each metric type maps to a HealthKit quantity type and specifies
/// which baseline period to use for z-score calculations.
public enum MonitorMetricType: String, CaseIterable, Sendable, Codable {

  // MARK: - Recovery & Sickness Monitor Metrics

  /// Resting heart rate in BPM (28-day baseline)
  case restingHeartRate = "restingHeartRate"

  /// Heart rate variability SDNN in milliseconds (28-day baseline)
  case heartRateVariability = "heartRateVariability"

  /// Sleeping wrist temperature deviation in °F (14-day baseline)
  /// Only available on Apple Watch Series 8+
  case wristTemperature = "wristTemperature"

  /// Respiratory rate in breaths per minute (14-day baseline)
  case respiratoryRate = "respiratoryRate"

  // MARK: - Stress & Workout Load Monitor Metrics

  /// Active energy burned in kcal (7-day and 28-day for acute:chronic ratio)
  case activeEnergy = "activeEnergy"

  /// Heart rate recovery after 1 minute in BPM (28-day baseline)
  case heartRateRecovery = "heartRateRecovery"

  // MARK: - Sleep Quality & Rhythm Monitor Metrics

  /// Total sleep duration in minutes (7-day and 28-day baseline)
  case sleepDuration = "sleepDuration"

  /// Deep sleep duration in minutes (7-day baseline)
  case deepSleep = "deepSleep"

  /// REM sleep duration in minutes (7-day baseline)
  case remSleep = "remSleep"

  /// Sleep efficiency as percentage 0-100 (7-day baseline)
  case sleepEfficiency = "sleepEfficiency"

  /// Bedtime as minutes from midnight (7-day baseline for variability)
  case bedtime = "bedtime"

  /// Wake time as minutes from midnight (7-day baseline for variability)
  case wakeTime = "wakeTime"

  // MARK: - Properties

  /// The HealthKit quantity type for this metric, if applicable
  public var healthKitType: HKQuantityType? {
    switch self {
    case .restingHeartRate:
      return HKQuantityType(.restingHeartRate)
    case .heartRateVariability:
      return HKQuantityType(.heartRateVariabilitySDNN)
    case .wristTemperature:
      return HKQuantityType(.appleSleepingWristTemperature)
    case .respiratoryRate:
      return HKQuantityType(.respiratoryRate)
    case .activeEnergy:
      return HKQuantityType(.activeEnergyBurned)
    case .heartRateRecovery:
      if #available(iOS 16.0, *) {
        return HKQuantityType(.heartRateRecoveryOneMinute)
      }
      return nil
    case .sleepDuration, .deepSleep, .remSleep, .sleepEfficiency, .bedtime, .wakeTime:
      // These are derived from sleep analysis, not direct quantity types
      return nil
    }
  }

  /// The HKUnit for this metric
  public var unit: HKUnit? {
    switch self {
    case .restingHeartRate, .heartRateRecovery:
      return .count().unitDivided(by: .minute()) // BPM
    case .heartRateVariability:
      return .secondUnit(with: .milli) // milliseconds
    case .wristTemperature:
      return .degreeFahrenheit()
    case .respiratoryRate:
      return .count().unitDivided(by: .minute()) // breaths per minute
    case .activeEnergy:
      return .largeCalorie()
    case .sleepDuration, .deepSleep, .remSleep:
      return .minute()
    case .sleepEfficiency:
      return nil // Percentage, no HKUnit
    case .bedtime, .wakeTime:
      return nil // Minutes from midnight, no HKUnit
    }
  }

  /// The primary baseline period for this metric (in days)
  public var primaryBaselineDays: Int {
    switch self {
    case .restingHeartRate, .heartRateVariability, .heartRateRecovery:
      return 28
    case .wristTemperature, .respiratoryRate:
      return 14
    case .activeEnergy, .sleepDuration, .deepSleep, .remSleep, .sleepEfficiency, .bedtime, .wakeTime:
      return 7
    }
  }

  /// Whether this metric also uses a 28-day baseline (for acute:chronic ratio)
  public var uses28DayBaseline: Bool {
    switch self {
    case .activeEnergy, .sleepDuration:
      return true
    default:
      return primaryBaselineDays == 28
    }
  }

  /// Whether this metric is required for its monitor to function
  public var isRequired: Bool {
    switch self {
    case .restingHeartRate, .heartRateVariability, .activeEnergy, .sleepDuration:
      return true
    default:
      return false
    }
  }

  /// The monitor this metric belongs to
  public var monitor: MonitorType {
    switch self {
    case .restingHeartRate, .heartRateVariability, .wristTemperature, .respiratoryRate:
      return .recovery
    case .activeEnergy, .heartRateRecovery:
      return .stress
    case .sleepDuration, .deepSleep, .remSleep, .sleepEfficiency, .bedtime, .wakeTime:
      return .sleep
    }
  }

  /// Human-readable display name
  public var displayName: String {
    switch self {
    case .restingHeartRate:
      return "Resting Heart Rate"
    case .heartRateVariability:
      return "Heart Rate Variability"
    case .wristTemperature:
      return "Wrist Temperature"
    case .respiratoryRate:
      return "Respiratory Rate"
    case .activeEnergy:
      return "Active Energy"
    case .heartRateRecovery:
      return "Heart Rate Recovery"
    case .sleepDuration:
      return "Sleep Duration"
    case .deepSleep:
      return "Deep Sleep"
    case .remSleep:
      return "REM Sleep"
    case .sleepEfficiency:
      return "Sleep Efficiency"
    case .bedtime:
      return "Bedtime"
    case .wakeTime:
      return "Wake Time"
    }
  }

  /// SF Symbol icon for this metric
  public var icon: SFSymbol {
    switch self {
    case .restingHeartRate:
      return .heartFill
    case .heartRateVariability:
      return .waveformPathEcg
    case .wristTemperature:
      return .thermometerMedium
    case .respiratoryRate:
      return .lungs
    case .activeEnergy:
      return .flameFill
    case .heartRateRecovery:
      return .arrowDownHeart
    case .sleepDuration:
      return .bedDoubleFill
    case .deepSleep:
      return .moonZzzFill
    case .remSleep:
      return .eyeFill
    case .sleepEfficiency:
      return .chartBarFill
    case .bedtime:
      return .moonFill
    case .wakeTime:
      return .sunriseFill
    }
  }
}

/// The three monitor types in the Monitor feature
public enum MonitorType: String, CaseIterable, Sendable, Codable {
  case recovery = "recovery"
  case stress = "stress"
  case sleep = "sleep"

  public var displayName: String {
    switch self {
    case .recovery:
      return "Recovery & Sickness"
    case .stress:
      return "Stress & Workout Load"
    case .sleep:
      return "Sleep Quality & Rhythm"
    }
  }

  /// The metrics used by this monitor
  public var metrics: [MonitorMetricType] {
    MonitorMetricType.allCases.filter { $0.monitor == self }
  }

  /// The required metrics for this monitor to function
  public var requiredMetrics: [MonitorMetricType] {
    metrics.filter { $0.isRequired }
  }
}
