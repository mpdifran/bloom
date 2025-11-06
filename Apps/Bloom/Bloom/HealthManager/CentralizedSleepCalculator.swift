//
//  CentralizedSleepCalculator.swift
//  Bloom
//
//  Created by Assistant on 2025-01-27.
//

import Foundation
import HealthKit
import CoreHealth
import CoreNetwork
import BloomFoundation

actor CentralizedSleepCalculator {
  static let shared = CentralizedSleepCalculator()

  private let healthStoreFetcher = HealthStoreFetcher.shared

  private init() { }

  func calculateSleepSessionForTodayInsights(for date: Date) async -> SleepSession? {
    // Search backwards from now to capture the complete sleep session (including any that's ongoing or just ended)
    let now = Date()
    let lookbackRange = DateRange.trailingDays(from: now, numberOfDays: 3)
    let allSleepAnalyses = await healthStoreFetcher.fetchSleepAnalysis(dateRange: lookbackRange)

    // For "today's insights", we want last night's sleep which ended TODAY (date + 1 day)
    // The date parameter represents "yesterday" when called from TodayInsightsManager
    guard let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: date) else { return nil }
    let filteredSleepAnalyses = allSleepAnalyses.filter { Calendar.current.isDate($0.endDate, inSameDayAs: nextDay) }

    // Should only get one sleep session for "last night"
    guard let sleepAnalysis = filteredSleepAnalyses.first else { return nil }

    // Calculate trends based on previous week's sleep
    let previousWeekRange = DateRange.trailingDays(from: date, numberOfDays: 7)
    let previousSleepAnalyses = await healthStoreFetcher.fetchSleepAnalysis(dateRange: previousWeekRange)

    let bedtimeTrends = calculateBedtimeTrends(current: [sleepAnalysis], previous: previousSleepAnalyses)
    let wakeupTrends = calculateWakeupTrends(current: [sleepAnalysis], previous: previousSleepAnalyses)
    let efficiencyTrends = calculateEfficiencyTrends(current: [sleepAnalysis], previous: previousSleepAnalyses)

    // Build the sleep session
    let totalSleepQuantity = HKQuantity(unit: .minute(), doubleValue: sleepAnalysis.overallMinutes)
    let totalSleepTime = await totalSleepQuantity.displayString(for: .hour(), formatter: .oneDecimalPlace)

    let deepSleepString = sleepAnalysis.hasDetailedSleepCategories ? await HKQuantity(unit: .minute(), doubleValue: sleepAnalysis.deepSleepMinutes).displayString(for: .minute(), formatter: .noDecimalPlaces) : nil
    let coreSleepString = sleepAnalysis.hasDetailedSleepCategories ? await HKQuantity(unit: .minute(), doubleValue: sleepAnalysis.coreSleepMinutes).displayString(for: .minute(), formatter: .noDecimalPlaces) : nil
    let remSleepString = sleepAnalysis.hasDetailedSleepCategories ? await HKQuantity(unit: .minute(), doubleValue: sleepAnalysis.remSleepMinutes).displayString(for: .minute(), formatter: .noDecimalPlaces) : nil
    let awakeTimeString = sleepAnalysis.hasDetailedSleepCategories ? await HKQuantity(unit: .minute(), doubleValue: sleepAnalysis.awakeSleepMinutes).displayString(for: .minute(), formatter: .noDecimalPlaces) : nil

    let heartRateString = sleepAnalysis.averageHeartRate.map { "\(Int($0)) bpm" }
    let respiratoryRateString = sleepAnalysis.respiratoryRate.average(keyPath: \.averageRespiratoryRate) > 0 ? "\(Int(sleepAnalysis.respiratoryRate.average(keyPath: \.averageRespiratoryRate))) breaths/min" : nil
    let soundLevelString = sleepAnalysis.averageSoundLevel > 0 ? "\(Int(sleepAnalysis.averageSoundLevel)) dB" : nil

    let wristTemperatureString: String?
    if let wristTemp = sleepAnalysis.wristTemperature?.averageWristTemperature {
      let tempQuantity = HKQuantity(unit: .degreeFahrenheit(), doubleValue: wristTemp)
      wristTemperatureString = await tempQuantity.displayString(for: .degreeFahrenheit(), formatter: .oneDecimalPlace)
    } else {
      wristTemperatureString = nil
    }

    let bedtimeLocalString = formatTimeLocal(sleepAnalysis.startDate)
    let wakeupTimeLocalString = formatTimeLocal(sleepAnalysis.endDate)

    let sleepEfficiency = calculateSleepEfficiency(sleepAnalysis)
    let sleepEfficiencyString = sleepEfficiency.map { String(format: "%.1f%%", $0) }

    let bedtimeTrend = bedtimeTrends.first
    let wakeupTrend = wakeupTrends.first
    let efficiencyTrend = efficiencyTrends.first

    return SleepSession(
      bedtimeLocal: bedtimeLocalString,
      wakeupTimeLocal: wakeupTimeLocalString,
      totalSleepTime: totalSleepTime,
      sleepScore: sleepAnalysis.overallScore,
      deepSleep: deepSleepString,
      coreSleep: coreSleepString,
      remSleep: remSleepString,
      awakeTime: awakeTimeString,
      averageHeartRate: heartRateString,
      averageRespiratoryRate: respiratoryRateString,
      averageSoundLevel: soundLevelString,
      wristTemperature: wristTemperatureString,
      bedtimeTrend: bedtimeTrend,
      wakeupTimeTrend: wakeupTrend,
      sleepEfficiency: sleepEfficiencyString,
      sleepEfficiencyTrend: efficiencyTrend
    )
  }

  func calculateSleepMetricsForBiologicalAge(dateRange: DateRange) async -> BiologicalAgeHealthData.SleepMetrics? {
    let sleepAnalyses = await healthStoreFetcher.fetchSleepAnalysis(dateRange: dateRange)

    guard !sleepAnalyses.isEmpty else { return nil }


    let durations = sleepAnalyses.map { $0.overallMinutes }
    let averageDuration = durations.reduce(0, +) / Double(durations.count)

    let efficiencies = sleepAnalyses.compactMap { calculateSleepEfficiency($0) }
    let averageEfficiency = efficiencies.isEmpty ? nil : efficiencies.reduce(0, +) / Double(efficiencies.count)

    let deepSleepMinutes = sleepAnalyses.map { $0.deepSleepMinutes }
    let averageDeepMinutes = deepSleepMinutes.isEmpty ? nil : deepSleepMinutes.reduce(0, +) / Double(deepSleepMinutes.count)

    let remSleepMinutes = sleepAnalyses.map { $0.remSleepMinutes }
    let averageRemMinutes = remSleepMinutes.isEmpty ? nil : remSleepMinutes.reduce(0, +) / Double(remSleepMinutes.count)

    let wakeMinutes = sleepAnalyses.map { $0.awakeSleepMinutes }
    let averageWakeMinutes = wakeMinutes.isEmpty ? nil : wakeMinutes.reduce(0, +) / Double(wakeMinutes.count)

    let deepSleepPercentage: Double? = {
      guard let deepMinutes = averageDeepMinutes, averageDuration > 0 else { return nil }
      return (deepMinutes / averageDuration) * 100
    }()

    let remSleepPercentage: Double? = {
      guard let remMinutes = averageRemMinutes, averageDuration > 0 else { return nil }
      return (remMinutes / averageDuration) * 100
    }()


    let durationDisplayString = await HKQuantity(unit: .hour(), doubleValue: averageDuration / 60).displayString(for: .hour())

    let deepSleepDisplayString: String?
    if let minutes = averageDeepMinutes {
      deepSleepDisplayString = await HKQuantity(unit: .minute(), doubleValue: minutes).displayString(for: .minute())
    } else {
      deepSleepDisplayString = nil
    }

    let remSleepDisplayString: String?
    if let minutes = averageRemMinutes {
      remSleepDisplayString = await HKQuantity(unit: .minute(), doubleValue: minutes).displayString(for: .minute())
    } else {
      remSleepDisplayString = nil
    }

    let wakeDisplayString: String?
    if let minutes = averageWakeMinutes {
      wakeDisplayString = await HKQuantity(unit: .minute(), doubleValue: minutes).displayString(for: .minute())
    } else {
      wakeDisplayString = nil
    }

    let bedtimeMetric = await calculateAverageBedtimeSimple(sleepAnalyses: sleepAnalyses)
    let wakeupMetric = await calculateAverageWakeupTimeSimple(sleepAnalyses: sleepAnalyses)

    return BiologicalAgeHealthData.SleepMetrics(
      averageSleepDuration: BiologicalAgeHealthData.MetricValue(
        value: durationDisplayString
      ),
      averageSleepEfficiency: averageEfficiency.map {
        BiologicalAgeHealthData.MetricValue(value: String(format: "%.1f%%", $0))
      },
      averageDeepSleep: {
        if let displayString = deepSleepDisplayString {
          return BiologicalAgeHealthData.SleepMetrics.SleepStageMetric(
            averageMinutes: displayString,
            averagePercentage: String(format: "%.1f%%", deepSleepPercentage ?? 0)
          )
        } else {
          return nil
        }
      }(),
      averageRemSleep: {
        if let displayString = remSleepDisplayString {
          return BiologicalAgeHealthData.SleepMetrics.SleepStageMetric(
            averageMinutes: displayString,
            averagePercentage: String(format: "%.1f%%", remSleepPercentage ?? 0)
          )
        } else {
          return nil
        }
      }(),
      averageWakeMinutes: {
        if let displayString = wakeDisplayString {
          return BiologicalAgeHealthData.MetricValue(
            value: displayString
          )
        } else {
          return nil
        }
      }(),
      averageBedtime: bedtimeMetric,
      averageWakeupTime: wakeupMetric
    )
  }

  private func calculateAverageBedtimeSimple(sleepAnalyses: [SleepAnalysis]) async -> BiologicalAgeHealthData.MetricValue? {
    guard !sleepAnalyses.isEmpty else { return nil }

    let bedtimeMinutes = sleepAnalyses.map { getMinutesFromMidnight($0.startDate) }
    let averageMinutes = bedtimeMinutes.reduce(0, +) / Double(bedtimeMinutes.count)
    let averageTime = formatMinutesAsTime(averageMinutes)

    return BiologicalAgeHealthData.MetricValue(value: averageTime)
  }

  private func calculateAverageWakeupTimeSimple(sleepAnalyses: [SleepAnalysis]) async -> BiologicalAgeHealthData.MetricValue? {
    guard !sleepAnalyses.isEmpty else { return nil }

    let wakeupMinutes = sleepAnalyses.map { getMinutesFromMidnight($0.endDate) }
    let averageMinutes = wakeupMinutes.reduce(0, +) / Double(wakeupMinutes.count)
    let averageTime = formatMinutesAsTime(averageMinutes)

    return BiologicalAgeHealthData.MetricValue(value: averageTime)
  }

  private func calculateSleepEfficiency(_ sleepAnalysis: SleepAnalysis) -> Double? {
    guard sleepAnalysis.overallMinutesIncludingAwake > 0 else { return nil }
    return (sleepAnalysis.overallMinutes / sleepAnalysis.overallMinutesIncludingAwake) * 100
  }

  private func formatTimeLocal(_ date: Date) -> String {
    return DateFormatter.mediumDateShortTimeLowercase.string(from: date)
  }

  private func calculateBedtimeTrends(current: [SleepAnalysis], previous: [SleepAnalysis]) -> [String] {
    guard !previous.isEmpty else {
      return current.map { _ in "similar to last 7 days average" }
    }

    let averageBedtimeMinutes = previous.map { getMinutesFromMidnight($0.startDate) }.reduce(0, +) / Double(previous.count)

    return current.map { analysis in
      let currentMinutes = getMinutesFromMidnight(analysis.startDate)
      let difference = currentMinutes - averageBedtimeMinutes

      if abs(difference) < 15 {
        return "similar to last 7 days average"
      } else if difference < 0 {
        return "earlier than last 7 days average"
      } else {
        return "later than last 7 days average"
      }
    }
  }

  private func calculateWakeupTrends(current: [SleepAnalysis], previous: [SleepAnalysis]) -> [String] {
    guard !previous.isEmpty else {
      return current.map { _ in "similar to last 7 days average" }
    }

    let averageWakeupMinutes = previous.map { getMinutesFromMidnight($0.endDate) }.reduce(0, +) / Double(previous.count)

    return current.map { analysis in
      let currentMinutes = getMinutesFromMidnight(analysis.endDate)
      let difference = currentMinutes - averageWakeupMinutes

      if abs(difference) < 15 {
        return "similar to last 7 days average"
      } else if difference < 0 {
        return "earlier than last 7 days average"
      } else {
        return "later than last 7 days average"
      }
    }
  }

  private func calculateEfficiencyTrends(current: [SleepAnalysis], previous: [SleepAnalysis]) -> [String] {
    guard !previous.isEmpty else {
      return current.map { _ in "similar to last 7 days average" }
    }

    let previousEfficiencies = previous.compactMap { calculateSleepEfficiency($0) }
    guard !previousEfficiencies.isEmpty else {
      return current.map { _ in "similar to last 7 days average" }
    }

    let averageEfficiency = previousEfficiencies.reduce(0, +) / Double(previousEfficiencies.count)

    return current.map { analysis in
      guard let currentEfficiency = calculateSleepEfficiency(analysis) else {
        return "similar to last 7 days average"
      }

      let difference = currentEfficiency - averageEfficiency

      if abs(difference) < 5 {
        return "similar to last 7 days average"
      } else if difference > 0 {
        return "better than last 7 days average"
      } else {
        return "worse than last 7 days average"
      }
    }
  }

  private func getMinutesFromMidnight(_ date: Date) -> Double {
    let calendar = Calendar.current
    let components = calendar.dateComponents([.hour, .minute], from: date)
    let hours = Double(components.hour ?? 0)
    let minutes = Double(components.minute ?? 0)

    var totalMinutes = hours * 60 + minutes

    if totalMinutes < 12 * 60 {
      totalMinutes += 24 * 60
    }

    return totalMinutes
  }

  private func calculateAverageBedtime(sleepAnalyses: [SleepAnalysis], previousAnalyses: [SleepAnalysis]) async -> BiologicalAgeHealthData.MetricValue? {
    guard !sleepAnalyses.isEmpty else { return nil }

    let bedtimeMinutes = sleepAnalyses.map { getMinutesFromMidnight($0.startDate) }
    let averageMinutes = bedtimeMinutes.reduce(0, +) / Double(bedtimeMinutes.count)

    let averageTime = formatMinutesAsTime(averageMinutes)

    return BiologicalAgeHealthData.MetricValue(
      value: averageTime
    )
  }

  private func calculateAverageWakeupTime(sleepAnalyses: [SleepAnalysis], previousAnalyses: [SleepAnalysis]) async -> BiologicalAgeHealthData.MetricValue? {
    guard !sleepAnalyses.isEmpty else { return nil }

    let wakeupMinutes = sleepAnalyses.map { getMinutesFromMidnight($0.endDate) }
    let averageMinutes = wakeupMinutes.reduce(0, +) / Double(wakeupMinutes.count)

    let averageTime = formatMinutesAsTime(averageMinutes)

    return BiologicalAgeHealthData.MetricValue(
      value: averageTime
    )
  }

  private func formatMinutesAsTime(_ totalMinutes: Double) -> String {
    var adjustedMinutes = totalMinutes
    if adjustedMinutes >= 24 * 60 {
      adjustedMinutes -= 24 * 60
    }

    let hours = Int(adjustedMinutes) / 60
    let minutes = Int(adjustedMinutes) % 60

    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    formatter.timeZone = TimeZone.current

    let calendar = Calendar.current
    var components = DateComponents()
    components.hour = hours
    components.minute = minutes

    if let date = calendar.date(from: components) {
      return formatter.string(from: date)
    }

    return String(format: "%d:%02d %@", hours % 12 == 0 ? 12 : hours % 12, minutes, hours < 12 ? "AM" : "PM")
  }

}
