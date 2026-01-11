//
//  BackgroundTaskScheduler.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation
import BackgroundTasks
import BloomModel

final class BackgroundTaskScheduler: Sendable {
  static let shared = BackgroundTaskScheduler()

  private init() { }
}

// MARK: - Reminder Notification Tasks

extension BackgroundTaskScheduler {

  func scheduleReminderNotificationUpdateTask() {
    let request = BGAppRefreshTaskRequest(identifier: "update-reminder-notifications")
    // Schedule to run in 4-6 hours to periodically clean up notifications
    request.earliestBeginDate = Calendar.current.date(byAdding: .hour, value: 4, to: .now)

    do {
      try BGTaskScheduler.shared.submit(request)
      print("Reminder Notification Update Background Task Scheduled!")
    } catch(let error) {
      print("Reminder Notification Update Scheduling Error \(error.localizedDescription)")
    }
  }

  func updateReminderNotifications() async {
    print("Background task: Updating reminder notifications...")

    // Delegate to ReminderScheduler to handle all notification logic
    await ReminderScheduler.shared.cleanupCompletedNotifications()

    // Schedule the next background task
    scheduleReminderNotificationUpdateTask()
  }
}

// MARK: - Monitor Aggregation Tasks

extension BackgroundTaskScheduler {

  /// Schedules the monitor daily aggregation task to run overnight.
  /// Uses BGProcessingTask for longer processing time, requires device to be charging.
  func scheduleMonitorAggregationTask() {
    let request = BGProcessingTaskRequest(identifier: "monitor-daily-aggregation")
    // Schedule for overnight (around 2 AM), requires charging for battery efficiency
    request.requiresExternalPower = true
    request.requiresNetworkConnectivity = false
    request.earliestBeginDate = nextMonitorAggregationTime()

    do {
      try BGTaskScheduler.shared.submit(request)
      print("Monitor Aggregation Background Task Scheduled for \(request.earliestBeginDate?.description ?? "unknown")")
    } catch(let error) {
      print("Monitor Aggregation Scheduling Error: \(error.localizedDescription)")
    }
  }

  /// Runs the monitor aggregation task - calculates health metrics for today.
  func runMonitorAggregation() async {
    print("Background task: Running monitor aggregation...")

    do {
      // Get previous states before calculation (for change detection)
      let previousResults = await DetectionEngine.shared.getAllCachedResults()
      let previousStates: [MonitorType: MonitorStateValue] = Dictionary(
        uniqueKeysWithValues: previousResults.map { ($0.monitorType, $0.state) }
      )

      // Calculate today's metrics
      try await MonitorCalculator.shared.calculateMetricsForDate(Date())

      // Calculate new states
      let newResults = try await DetectionEngine.shared.calculateAllStates()

      // Check if any monitors transitioned to concerning state
      let hasNewConcerningState = newResults.contains { result in
        let previousState = previousStates[result.monitorType]
        return result.state.isConcerning && previousState != result.state
      }

      // Generate AI summary if there's a new concerning state
      if hasNewConcerningState {
        await generateAndCacheAISummary(for: newResults)
      } else if newResults.allSatisfy({ $0.state == .good }) {
        // Clear cache when all monitors return to Good
        await MonitorSummaryCache.shared.clearCache()
      }

      // Check for state changes and send notifications
      for result in newResults {
        let previousState = previousStates[result.monitorType]
        await MonitorNotificationScheduler.shared.scheduleNotificationIfNeeded(
          result: result,
          previousState: previousState
        )
      }

      print("Monitor aggregation completed successfully")
    } catch {
      print("Monitor aggregation failed: \(error.localizedDescription)")
    }

    // Schedule the next background task for tomorrow
    scheduleMonitorAggregationTask()
  }

  /// Generates an AI summary for the current monitor results and caches it.
  private func generateAndCacheAISummary(for results: [MonitorResult]) async {
    do {
      // Build monitor context JSON
      let monitorContext = try JSONEncoder().encode(results)
      guard let monitorContextString = String(data: monitorContext, encoding: .utf8) else {
        print("BackgroundTaskScheduler: Failed to encode monitor context")
        return
      }

      // Build health context (simplified - baseline metrics)
      let healthContext = "Monitor results included in monitorContext"

      // Get timezone
      let timezone = TimeZone.current.identifier

      // Create request
      let request = MonitorSummaryRequest(
        monitorContext: monitorContextString,
        healthContext: healthContext,
        timezone: timezone
      )

      // Call backend API
      let urlRequest = try await URLRequest.Monitor.getSummary(body: request)
      let summary: MonitorSummaryResponse = try await URLSession.shared.authenticatedBloomRequestWithResponse(
        request: urlRequest,
        responseType: MonitorSummaryResponse.self
      )

      // Cache the summary
      await MonitorSummaryCache.shared.cache(summary)

      print("BackgroundTaskScheduler: AI summary generated and cached")
    } catch {
      // Don't fail the aggregation if AI summary fails
      print("BackgroundTaskScheduler: Failed to generate AI summary: \(error.localizedDescription)")
    }
  }

  /// Calculates the next time to run the monitor aggregation (2 AM local time).
  private func nextMonitorAggregationTime() -> Date {
    let calendar = Calendar.current
    var components = calendar.dateComponents([.year, .month, .day], from: Date())
    components.hour = 2
    components.minute = 0
    components.second = 0

    var scheduledDate = calendar.date(from: components) ?? Date()

    // If 2 AM today has already passed, schedule for tomorrow
    if scheduledDate <= Date() {
      scheduledDate = calendar.date(byAdding: .day, value: 1, to: scheduledDate) ?? Date()
    }

    return scheduledDate
  }
}
