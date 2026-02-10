//
//  StepsTimelineProvider.swift
//  BloomWidgets
//
//  Created by Claude Code on 2026-02-09.
//

import AppIntents
import BloomFoundation
import CoreHealth
import Foundation
@preconcurrency import HealthKit
import WidgetKit

struct StepsTimelineProvider: AppIntentTimelineProvider {
  typealias Entry = StepsEntry
  typealias Intent = StepsConfigurationIntent

  func placeholder(in context: Context) -> StepsEntry {
    .placeholder()
  }

  func snapshot(for configuration: StepsConfigurationIntent, in context: Context) async -> StepsEntry {
    if context.isPreview {
      return .placeholder(for: configuration.timePeriod)
    }
    return await makeEntry(for: configuration.timePeriod)
  }

  func timeline(for configuration: StepsConfigurationIntent, in context: Context) async -> Timeline<StepsEntry> {
    let entry = await makeEntry(for: configuration.timePeriod)
    let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: .now) ?? .now
    return Timeline(entries: [entry], policy: .after(nextUpdate))
  }
}

// MARK: - Data Loading

private extension StepsTimelineProvider {

  func makeEntry(for timePeriod: StepsWidgetTimePeriod) async -> StepsEntry {
    let calendar = Calendar.current
    let now = Date()
    let params = dateParameters(for: timePeriod, calendar: calendar, now: now)

    // Fetch total steps for the period
    let stepsQuantity = await HealthStoreFetcher.shared.fetchTotalQuantity(
      for: .stepCount,
      dateRange: params.dateRange
    )
    let steps: Int? = stepsQuantity.map { Int($0.doubleValue(for: .count()).rounded()) }

    // Determine preferred distance unit
    let distanceUnit: HKUnit
    let distanceUnitString: String
    if let unitString = UserDefaults.group.string(forKey: "HealthUnitPreferences.distanceUnit") {
      let unit = HKUnit(from: unitString)
      distanceUnit = unit
      distanceUnitString = unit.unitString
    } else if Locale.current.measurementSystem == .metric {
      distanceUnit = .meterUnit(with: .kilo)
      distanceUnitString = "km"
    } else {
      distanceUnit = .mile()
      distanceUnitString = "mi"
    }

    // Fetch total walking/running distance for the period
    let distanceQuantity = await HealthStoreFetcher.shared.fetchTotalQuantity(
      for: .distanceWalkingRunning,
      dateRange: params.dateRange
    )
    let distance: Double? = distanceQuantity.map { $0.doubleValue(for: distanceUnit) }

    // Fetch interval data for chart
    let intervalSamples = await HealthStoreFetcher.shared.fetchCollatedQuantity(
      for: .stepCount,
      unit: .count(),
      interval: params.interval,
      dateRange: params.chartRange
    )

    // Build cumulative chart points
    let chartDataPoints = buildCumulativeChartPoints(
      from: intervalSamples,
      startDate: params.chartRange.start,
      timePeriod: timePeriod,
      totalSlots: params.totalSlots,
      now: now
    )

    return StepsEntry(
      date: now,
      timePeriod: timePeriod,
      steps: steps,
      distance: distance,
      distanceUnitString: distanceUnitString,
      chartDataPoints: chartDataPoints,
      totalSlots: params.totalSlots
    )
  }

  struct DateParameters {
    let dateRange: DateRange
    let chartRange: DateRange
    let interval: DateComponents
    let totalSlots: Int
  }

  func dateParameters(
    for timePeriod: StepsWidgetTimePeriod,
    calendar: Calendar,
    now: Date
  ) -> DateParameters {
    switch timePeriod {
    case .daily:
      let startOfDay = calendar.startOfDay(for: now)
      let dateRange = DateRange(startOfDay, calendar.endOfDay(for: now))
      let chartRange = DateRange(startOfDay, now)
      return DateParameters(dateRange: dateRange, chartRange: chartRange, interval: DateComponents(hour: 1), totalSlots: 24)

    case .weekly:
      // Sunday-aligned week (matching YouStatsCalculator)
      var cal = calendar
      cal.firstWeekday = 1
      let todayWeekday = cal.component(.weekday, from: now)
      let weekStart = cal.date(byAdding: .day, value: -(todayWeekday - 1), to: cal.startOfDay(for: now)) ?? cal.startOfDay(for: now)
      let dateRange = DateRange(weekStart, now)
      let chartRange = DateRange(weekStart, now)
      return DateParameters(dateRange: dateRange, chartRange: chartRange, interval: DateComponents(hour: 4), totalSlots: 42)

    case .monthly:
      let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? calendar.startOfDay(for: now)
      let dateRange = DateRange(monthStart, now)
      let chartRange = DateRange(monthStart, now)
      let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
      return DateParameters(dateRange: dateRange, chartRange: chartRange, interval: DateComponents(day: 1), totalSlots: daysInMonth)

    case .yearly:
      let year = calendar.component(.year, from: now)
      let yearStart = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? calendar.startOfDay(for: now)
      let dateRange = DateRange(yearStart, now)
      let chartRange = DateRange(yearStart, now)
      return DateParameters(dateRange: dateRange, chartRange: chartRange, interval: DateComponents(month: 1), totalSlots: 12)
    }
  }

  func buildCumulativeChartPoints(
    from samples: [DateQuantitySample],
    startDate: Date,
    timePeriod: StepsWidgetTimePeriod,
    totalSlots: Int,
    now: Date
  ) -> [StepChartPoint] {
    let calendar = Calendar.current
    var cumulativeTotal = 0
    var points = [StepChartPoint(slot: 0, cumulativeSteps: 0)]

    for sample in samples {
      guard sample.date < now else { continue }

      let slot: Int
      switch timePeriod {
      case .daily:
        slot = Int(sample.date.timeIntervalSince(startDate) / 3600)
      case .weekly:
        slot = Int(sample.date.timeIntervalSince(startDate) / (4 * 3600))
      case .monthly:
        slot = calendar.component(.day, from: sample.date) - 1
      case .yearly:
        slot = calendar.component(.month, from: sample.date) - 1
      }

      guard slot >= 0, slot < totalSlots else { continue }
      cumulativeTotal += Int(sample.quantity.doubleValue(for: .count()).rounded())
      points.append(StepChartPoint(slot: slot, cumulativeSteps: cumulativeTotal))
    }

    return points
  }
}
