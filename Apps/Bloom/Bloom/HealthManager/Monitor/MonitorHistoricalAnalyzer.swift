//
//  MonitorHistoricalAnalyzer.swift
//  Bloom
//
//  Created by Claude on 2026-01-12.
//

import Foundation
import DataContainer
import BloomFoundation

/// Snapshot of a single metric's data for a given day
public struct MetricSnapshot: Sendable {
  public let metricType: MonitorMetricType
  public let value: Double?
  public let quality: String?
  public let baseline7Day: Double?
  public let baseline28Day: Double?
  public let zScore: Double?
}

/// Complete analysis data for a single day
public struct DailyAnalysisData: Sendable {
  public let date: Date
  public let monitorResults: [MonitorResult]
  public let metrics: [MetricSnapshot]
}

/// Analyzes historical health data to find monitor state changes and notification triggers.
/// Used in developer settings to understand when monitors would have activated.
actor MonitorHistoricalAnalyzer {

  /// Analyzes the given date range and returns all significant events.
  /// - Parameters:
  ///   - startDate: The first date to analyze
  ///   - endDate: The last date to analyze
  ///   - progressHandler: Optional callback to report progress (0.0 to 1.0)
  /// - Returns: Array of historical events sorted by date
  func analyze(
    from startDate: Date,
    to endDate: Date,
    progressHandler: (@Sendable (Double) -> Void)? = nil
  ) async throws -> [HistoricalMonitorEvent] {
    var events: [HistoricalMonitorEvent] = []
    let calendar = Calendar.current

    // Calculate the date range to backfill
    // We need baseline data (30 days before analysis start) through analysis end
    let lookbackDays = 30
    guard let backfillStartDate = calendar.date(byAdding: .day, value: -lookbackDays, to: startDate),
          let rangeDays = calendar.dateComponents([.day], from: startDate, to: endDate).day else {
      return []
    }

    // Backfill only the specific date range we need (baseline period + analysis period)
    try await MonitorCalculator.shared.backfillMetrics(from: backfillStartDate, to: endDate)

    // Calculate states for each day in the analysis range
    var previousResults: [MonitorType: MonitorResult] = [:]
    var currentDate = startDate
    var daysProcessed = 0
    let totalDaysToProcess = rangeDays + 1

    while currentDate <= endDate {
      // Report progress
      let progress = Double(daysProcessed) / Double(totalDaysToProcess)
      progressHandler?(progress)

      // Calculate states for this day
      let results = try await DetectionEngine.shared.calculateAllStates(for: currentDate)

      for result in results {
        let previousState = previousResults[result.monitorType]?.state

        // Check for state change
        if previousState != result.state {
          let event = HistoricalMonitorEvent(
            date: currentDate,
            monitorType: result.monitorType,
            eventType: .stateChange,
            previousState: previousState,
            newState: result.state,
            confidence: result.confidence,
            signals: result.signals,
            findings: result.findings,
            stressSubtype: result.stressSubtype
          )
          events.append(event)

          // Check if this would trigger a notification
          // Notification triggers when transitioning TO a concerning state FROM a non-concerning state
          let wasNotConcerning = !(previousState?.isConcerning ?? false)
          let isNowConcerning = result.state.isConcerning

          if isNowConcerning && wasNotConcerning {
            let notificationEvent = HistoricalMonitorEvent(
              date: currentDate,
              monitorType: result.monitorType,
              eventType: .notificationTrigger,
              previousState: previousState,
              newState: result.state,
              confidence: result.confidence,
              signals: result.signals,
              findings: result.findings,
              stressSubtype: result.stressSubtype
            )
            events.append(notificationEvent)
          }
        }

        previousResults[result.monitorType] = result
      }

      // Move to next day
      guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
        break
      }
      currentDate = nextDate
      daysProcessed += 1
    }

    // Final progress update
    progressHandler?(1.0)

    return events.sorted { $0.date < $1.date }
  }

  /// Analyzes the given date range and returns full daily data including metrics.
  /// Used for exporting comprehensive analysis data for debugging.
  /// - Parameters:
  ///   - startDate: The first date to analyze
  ///   - endDate: The last date to analyze
  ///   - progressHandler: Optional callback to report progress (0.0 to 1.0)
  /// - Returns: Tuple of events and full daily analysis data
  func analyzeWithFullData(
    from startDate: Date,
    to endDate: Date,
    progressHandler: (@Sendable (Double) -> Void)? = nil
  ) async throws -> (events: [HistoricalMonitorEvent], dailyData: [DailyAnalysisData]) {
    var events: [HistoricalMonitorEvent] = []
    var dailyData: [DailyAnalysisData] = []
    let calendar = Calendar.current

    // Calculate the date range to backfill
    // We need baseline data (30 days before analysis start) through analysis end
    let lookbackDays = 30
    guard let backfillStartDate = calendar.date(byAdding: .day, value: -lookbackDays, to: startDate),
          let rangeDays = calendar.dateComponents([.day], from: startDate, to: endDate).day else {
      return ([], [])
    }

    // Backfill only the specific date range we need (baseline period + analysis period)
    try await MonitorCalculator.shared.backfillMetrics(from: backfillStartDate, to: endDate)

    // Fetch all metric samples for the date range
    let metricActor = DailyMetricSampleModelActor(modelContainer: ContainerHolder.shared.container)
    let dateRange = DateRange(startDate, endDate)
    let allSamples = try await metricActor.fetchSamples(
      metricTypes: MonitorMetricType.allCases.map(\.rawValue),
      dateRange: dateRange
    )

    // Group samples by date
    let samplesByDate = Dictionary(grouping: allSamples) { sample in
      calendar.startOfDay(for: sample.date)
    }

    // Calculate states for each day in the analysis range
    var previousResults: [MonitorType: MonitorResult] = [:]
    var currentDate = startDate
    var daysProcessed = 0
    let totalDaysToProcess = rangeDays + 1

    while currentDate <= endDate {
      // Report progress
      let progress = Double(daysProcessed) / Double(totalDaysToProcess)
      progressHandler?(progress)

      // Calculate states for this day
      let results = try await DetectionEngine.shared.calculateAllStates(for: currentDate)

      // Get metric samples for this day
      let dayStart = calendar.startOfDay(for: currentDate)
      let daySamples = samplesByDate[dayStart] ?? []

      // Create metric snapshots
      let metrics: [MetricSnapshot] = MonitorMetricType.allCases.compactMap { metricType in
        if let sample = daySamples.first(where: { $0.metricType == metricType.rawValue }) {
          return MetricSnapshot(
            metricType: metricType,
            value: sample.value,
            quality: sample.quality,
            baseline7Day: sample.baseline7Day,
            baseline28Day: sample.baseline28Day,
            zScore: sample.zScore
          )
        }
        return nil
      }

      // Create daily analysis data
      let dayData = DailyAnalysisData(
        date: currentDate,
        monitorResults: results,
        metrics: metrics
      )
      dailyData.append(dayData)

      for result in results {
        let previousState = previousResults[result.monitorType]?.state

        // Check for state change
        if previousState != result.state {
          let event = HistoricalMonitorEvent(
            date: currentDate,
            monitorType: result.monitorType,
            eventType: .stateChange,
            previousState: previousState,
            newState: result.state,
            confidence: result.confidence,
            signals: result.signals,
            findings: result.findings,
            stressSubtype: result.stressSubtype
          )
          events.append(event)

          // Check if this would trigger a notification
          let wasNotConcerning = !(previousState?.isConcerning ?? false)
          let isNowConcerning = result.state.isConcerning

          if isNowConcerning && wasNotConcerning {
            let notificationEvent = HistoricalMonitorEvent(
              date: currentDate,
              monitorType: result.monitorType,
              eventType: .notificationTrigger,
              previousState: previousState,
              newState: result.state,
              confidence: result.confidence,
              signals: result.signals,
              findings: result.findings,
              stressSubtype: result.stressSubtype
            )
            events.append(notificationEvent)
          }
        }

        previousResults[result.monitorType] = result
      }

      // Move to next day
      guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else {
        break
      }
      currentDate = nextDate
      daysProcessed += 1
    }

    // Final progress update
    progressHandler?(1.0)

    return (events.sorted { $0.date < $1.date }, dailyData.sorted { $0.date < $1.date })
  }
}
