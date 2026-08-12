//
//  MonitorMetricType.swift
//  Bloom
//
//  Created by Claude on 2026-01-09.
//

import Foundation
import HealthKit
import SFSafeSymbols
import CoreHealth

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

  /// Workout-based training load (7-day vs 28-day ratio)
  case trainingLoad = "trainingLoad"

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
    case .trainingLoad:
      // Derived from workouts, not a direct quantity type
      return nil
    case .sleepDuration, .deepSleep, .remSleep, .sleepEfficiency, .bedtime, .wakeTime:
      // These are derived from sleep analysis, not direct quantity types
      return nil
    }
  }

  /// The HKUnit for this metric
  public var unit: HKUnit? {
    switch self {
    case .restingHeartRate:
      return .count().unitDivided(by: .minute()) // BPM
    case .heartRateVariability:
      return .secondUnit(with: .milli) // milliseconds
    case .wristTemperature:
      return .degreeFahrenheit()
    case .respiratoryRate:
      return .count().unitDivided(by: .minute()) // breaths per minute
    case .sleepDuration, .deepSleep, .remSleep:
      return .minute()
    case .sleepEfficiency:
      return nil // Percentage, no HKUnit
    case .bedtime, .wakeTime:
      return nil // Minutes from midnight, no HKUnit
    case .trainingLoad:
      return nil // Percentage, no HKUnit
    }
  }

  /// The primary baseline period for this metric (in days)
  public var primaryBaselineDays: Int {
    switch self {
    case .restingHeartRate, .heartRateVariability:
      return 28
    case .wristTemperature, .respiratoryRate:
      return 14
    case .trainingLoad:
      return 7
    case .sleepDuration, .deepSleep, .remSleep, .sleepEfficiency, .bedtime, .wakeTime:
      return 7
    }
  }

  /// Whether this metric also uses a 28-day baseline (for acute:chronic ratio)
  public var uses28DayBaseline: Bool {
    switch self {
    case .sleepDuration, .trainingLoad:
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
    case .trainingLoad:
      return .stress
    case .sleepDuration, .sleepEfficiency, .bedtime, .wakeTime:
      return .sleep
    case .deepSleep, .remSleep:
      // Removed from sleep monitor due to noisy/unreliable data
      // Deep sleep still used in stress monitor for burnout detection
      return nil
    }
  }

  /// Human-readable display name
  public var displayName: String {
    switch self {
    case .restingHeartRate:
      return String(localized: "Resting Heart Rate")
    case .heartRateVariability:
      return String(localized: "Heart Rate Variability")
    case .wristTemperature:
      return String(localized: "Wrist Temperature")
    case .respiratoryRate:
      return String(localized: "Respiratory Rate")
    case .sleepDuration:
      return String(localized: "Sleep Duration")
    case .deepSleep:
      return String(localized: "Deep Sleep")
    case .remSleep:
      return String(localized: "REM Sleep")
    case .sleepEfficiency:
      return String(localized: "Sleep Efficiency")
    case .bedtime:
      return String(localized: "Bedtime")
    case .wakeTime:
      return String(localized: "Wake Time")
    case .trainingLoad:
      return String(localized: "Training Load")
    }
  }

  /// Short name for compact display
  public var shortName: String {
    switch self {
    case .restingHeartRate:
      return String(localized: "RHR")
    case .heartRateVariability:
      return String(localized: "HRV")
    case .wristTemperature:
      return String(localized: "Temp")
    case .respiratoryRate:
      return String(localized: "Respiratory rate")
    case .sleepDuration:
      return String(localized: "Sleep")
    case .deepSleep:
      return String(localized: "Deep sleep")
    case .remSleep:
      return String(localized: "REM")
    case .sleepEfficiency:
      return String(localized: "Efficiency")
    case .bedtime:
      return String(localized: "Bedtime")
    case .wakeTime:
      return String(localized: "Wake time")
    case .trainingLoad:
      return String(localized: "Training load")
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
    case .sleepDuration:
      return .bedDoubleFill
    case .deepSleep:
      return .moonZzzFill
    case .remSleep:
      return .eyeFill
    case .sleepEfficiency:
      return .chartBarFill
    case .bedtime:
      return .moonsetFill
    case .wakeTime:
      return .sunriseFill
    case .trainingLoad:
      return .flameFill
    }
  }

  /// Abbreviated unit string for display
  public var unitAbbreviation: String {
    switch self {
    case .restingHeartRate:
      return "bpm"
    case .heartRateVariability:
      return "ms"
    case .wristTemperature:
      return UnitTemperature(forLocale: .current).symbol
    case .respiratoryRate:
      return "br/min"
    case .sleepDuration, .deepSleep, .remSleep:
      return ""  // Formatted as hours:minutes
    case .sleepEfficiency:
      return "%"
    case .bedtime, .wakeTime:
      return ""  // Formatted as time
    case .trainingLoad:
      return "%"
    }
  }

  /// Format a value for display with appropriate unit
  @MainActor
  public func formatValue(_ value: Double) -> String {
    switch self {
    case .restingHeartRate, .heartRateVariability, .respiratoryRate:
      guard let unit = unit else { return "" }
      let quantity = HKQuantity(unit: unit, doubleValue: value)
      return quantity.displayString(for: unit)
    case .wristTemperature:
      return formatLocalizedTemperature(value)
    case .sleepDuration, .deepSleep, .remSleep:
      return formatMinutesAsHoursMinutes(value)
    case .sleepEfficiency:
      return "\(Int(value))%"
    case .bedtime, .wakeTime:
      return formatMinutesFromMidnightAsTime(value)
    case .trainingLoad:
      let sign = value >= 0 ? "+" : ""
      return "\(sign)\(Int(value))%"
    }
  }

  /// Format a value with abbreviated unit (for labels)
  @MainActor
  public func formatValueShort(_ value: Double) -> String {
    switch self {
    case .restingHeartRate, .heartRateVariability, .respiratoryRate:
      guard let unit = unit else { return "" }
      let quantity = HKQuantity(unit: unit, doubleValue: value)
      return quantity.displayString(for: unit, showUnits: false)
    case .wristTemperature:
      return formatLocalizedTemperature(value, showUnits: false)
    case .sleepDuration, .deepSleep, .remSleep:
      return formatMinutesAsHoursMinutesShort(value)
    case .sleepEfficiency:
      return "\(Int(value))"
    case .bedtime, .wakeTime:
      return formatMinutesFromMidnightAsTime(value)
    case .trainingLoad:
      let sign = value >= 0 ? "+" : ""
      return "\(sign)\(Int(value))"
    }
  }

  /// Format a difference value with sign and unit (e.g., "+10 bpm", "-45 min")
  @MainActor
  public func formatDifference(_ value: Double) -> String {
    let sign = value >= 0 ? "+" : ""
    switch self {
    case .restingHeartRate, .heartRateVariability, .respiratoryRate:
      guard let unit = unit else { return "" }
      let quantity = HKQuantity(unit: unit, doubleValue: abs(value))
      return "\(sign)\(quantity.displayString(for: unit))"
    case .wristTemperature:
      return formatLocalizedTemperatureDifference(value)
    case .sleepDuration, .deepSleep, .remSleep:
      return formatDifferenceAsMinutes(value)
    case .sleepEfficiency:
      return "\(sign)\(Int(value))%"
    case .bedtime, .wakeTime:
      return formatDifferenceAsMinutes(value)
    case .trainingLoad:
      let sign = value >= 0 ? "+" : ""
      return "\(sign)\(Int(value))%"
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

  private func formatLocalizedTemperature(_ fahrenheitValue: Double, showUnits: Bool = true) -> String {
    let measurement = Measurement(value: fahrenheitValue, unit: UnitTemperature.fahrenheit)
    let localizedValue = measurement.localizedValue
    let formatted = localizedValue.format(using: .oneDecimalPlace)
    if showUnits {
      let unit = UnitTemperature(forLocale: .current).symbol
      return "\(formatted)\(unit)"
    }
    return formatted
  }

  private func formatLocalizedTemperatureDifference(_ fahrenheitValue: Double) -> String {
    let measurement = Measurement(value: fahrenheitValue, unit: UnitTemperature.fahrenheit)
    let localizedValue = measurement.localizedValue
    let sign = localizedValue >= 0 ? "+" : ""
    let formatted = abs(localizedValue).format(using: .oneDecimalPlace)
    let unit = UnitTemperature(forLocale: .current).symbol
    return "\(sign)\(formatted)\(unit)"
  }
}

/// The three monitor types in the Monitor feature
public enum MonitorType: String, Equatable, CaseIterable, Sendable, Codable {
  case recovery = "recovery"
  case stress = "stress"
  case sleep = "sleep"

  public var displayName: String {
    switch self {
    case .recovery:
      return String(localized: "Recovery & Sickness")
    case .stress:
      return String(localized: "Stress & Workout Load")
    case .sleep:
      return String(localized: "Sleep Quality & Rhythm")
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
