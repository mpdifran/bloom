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
    case .restingHeartRate, .heartRateVariability, .sleepDuration:
      return true
    default:
      return false
    }
  }

  /// The monitor this metric belongs to
  public var monitor: MonitorType? {
    switch self {
    case .restingHeartRate, .heartRateVariability, .wristTemperature, .respiratoryRate:
      return .recovery
    case .heartRateRecovery:
      return .stress
    case .sleepDuration, .sleepEfficiency, .bedtime, .wakeTime:
      return .sleep
    case .deepSleep, .remSleep:
      // Removed from sleep monitor due to noisy/unreliable data
      // Deep sleep still used in stress monitor for burnout detection
      return nil
    case .activeEnergy:
      // Training load is computed from workouts via TrainingLoadSummary, not active energy samples
      return nil
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

  /// Abbreviated unit string for display
  public var unitAbbreviation: String {
    switch self {
    case .restingHeartRate, .heartRateRecovery:
      return "bpm"
    case .heartRateVariability:
      return "ms"
    case .wristTemperature:
      return UnitTemperature(forLocale: .current).symbol
    case .respiratoryRate:
      return "br/min"
    case .activeEnergy:
      return "kcal"
    case .sleepDuration, .deepSleep, .remSleep:
      return ""  // Formatted as hours:minutes
    case .sleepEfficiency:
      return "%"
    case .bedtime, .wakeTime:
      return ""  // Formatted as time
    }
  }

  /// Format a value for display with appropriate unit
  public func formatValue(_ value: Double) -> String {
    switch self {
    case .restingHeartRate, .heartRateRecovery:
      return "\(Int(value)) bpm"
    case .heartRateVariability:
      return "\(Int(value)) ms"
    case .wristTemperature:
      let measurement = Measurement(value: value, unit: UnitTemperature.fahrenheit)
      let localizedValue = measurement.localizedValue
      let unit = UnitTemperature(forLocale: .current).symbol
      return String(format: "%.1f%@", localizedValue, unit)
    case .respiratoryRate:
      return String(format: "%.1f br/min", value)
    case .activeEnergy:
      return "\(Int(value)) kcal"
    case .sleepDuration, .deepSleep, .remSleep:
      return formatMinutesAsHoursMinutes(value)
    case .sleepEfficiency:
      return "\(Int(value))%"
    case .bedtime, .wakeTime:
      return formatMinutesFromMidnightAsTime(value)
    }
  }

  /// Format a value with abbreviated unit (for labels)
  public func formatValueShort(_ value: Double) -> String {
    switch self {
    case .restingHeartRate, .heartRateRecovery:
      return "\(Int(value))"
    case .heartRateVariability:
      return "\(Int(value))"
    case .wristTemperature:
      let measurement = Measurement(value: value, unit: UnitTemperature.fahrenheit)
      return String(format: "%.1f", measurement.localizedValue)
    case .respiratoryRate:
      return String(format: "%.1f", value)
    case .activeEnergy:
      return "\(Int(value))"
    case .sleepDuration, .deepSleep, .remSleep:
      return formatMinutesAsHoursMinutesShort(value)
    case .sleepEfficiency:
      return "\(Int(value))"
    case .bedtime, .wakeTime:
      return formatMinutesFromMidnightAsTime(value)
    }
  }

  /// Format a difference value with sign and unit (e.g., "+10 bpm", "-45 min")
  public func formatDifference(_ value: Double) -> String {
    let sign = value >= 0 ? "+" : ""
    switch self {
    case .restingHeartRate, .heartRateRecovery:
      return "\(sign)\(Int(value)) bpm"
    case .heartRateVariability:
      return "\(sign)\(Int(value)) ms"
    case .wristTemperature:
      let measurement = Measurement(value: value, unit: UnitTemperature.fahrenheit)
      let localizedValue = measurement.localizedValue
      let unit = UnitTemperature(forLocale: .current).symbol
      return String(format: "%@%.1f%@", sign, localizedValue, unit)
    case .respiratoryRate:
      return String(format: "%@%.1f br/min", sign, value)
    case .activeEnergy:
      return "\(sign)\(Int(value)) kcal"
    case .sleepDuration, .deepSleep, .remSleep:
      return formatDifferenceAsMinutes(value)
    case .sleepEfficiency:
      return "\(sign)\(Int(value))%"
    case .bedtime, .wakeTime:
      return formatDifferenceAsMinutes(value)
    }
  }

  private func formatDifferenceAsMinutes(_ minutes: Double) -> String {
    let sign = minutes >= 0 ? "+" : ""
    let absMinutes = abs(Int(minutes))
    let hours = absMinutes / 60
    let mins = absMinutes % 60
    if hours > 0 && mins > 0 {
      return "\(sign)\(hours)h \(mins)m"
    } else if hours > 0 {
      return "\(sign)\(hours)h"
    } else {
      return "\(sign)\(Int(minutes))m"
    }
  }

  private func formatMinutesAsHoursMinutes(_ minutes: Double) -> String {
    let hours = Int(minutes) / 60
    let mins = Int(minutes) % 60
    if hours > 0 && mins > 0 {
      return "\(hours)h \(mins)m"
    } else if hours > 0 {
      return "\(hours)h"
    } else {
      return "\(mins)m"
    }
  }

  private func formatMinutesAsHoursMinutesShort(_ minutes: Double) -> String {
    let hours = Int(minutes) / 60
    let mins = Int(minutes) % 60
    if hours > 0 {
      return "\(hours):\(String(format: "%02d", mins))"
    } else {
      return "\(mins)m"
    }
  }

  private func formatMinutesFromMidnightAsTime(_ minutes: Double) -> String {
    var adjustedMinutes = Int(minutes)
    // Handle negative values (before midnight) and values > 24h
    while adjustedMinutes < 0 {
      adjustedMinutes += 24 * 60
    }
    while adjustedMinutes >= 24 * 60 {
      adjustedMinutes -= 24 * 60
    }
    let hour = adjustedMinutes / 60
    let minute = adjustedMinutes % 60
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    var components = DateComponents()
    components.hour = hour
    components.minute = minute
    guard let date = Calendar.current.date(from: components) else {
      return "--:--"
    }
    return formatter.string(from: date)
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
    MonitorMetricType.allCases.filter { $0.monitor == .some(self) }
  }

  /// Metrics used for state detection (may include metrics from other monitors).
  /// Use this for displaying all relevant metrics in detail views.
  public var detectionMetrics: [MonitorMetricType] {
    switch self {
    case .recovery:
      return metrics
    case .stress:
      // Includes burnout detection metrics from other monitors
      return [
        .heartRateRecovery,      // Owned - low recovery indicates overtraining
        .heartRateVariability,   // From recovery - HRV trend analysis
        .sleepEfficiency,        // From sleep - burnout signal
        .deepSleep,              // From sleep - burnout signal
        .restingHeartRate        // From recovery - elevated RHR signal
      ]
    case .sleep:
      return metrics
    }
  }

  /// The required metrics for this monitor to function
  public var requiredMetrics: [MonitorMetricType] {
    metrics.filter { $0.isRequired }
  }
}
