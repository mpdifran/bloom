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

  /// Schedules the monitor aggregation task to run every 12 hours.
  /// Uses BGProcessingTask for longer processing time.
  func scheduleMonitorAggregationTask() {
    let request = BGProcessingTaskRequest(identifier: "monitor-daily-aggregation")
    request.requiresExternalPower = false
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
    internalLog(.monitorAggregation, "Starting monitor aggregation")

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

      // Check for state changes and send notifications
      for result in newResults {
        let previousState = previousStates[result.monitorType]
        await MonitorNotificationScheduler.shared.scheduleNotificationIfNeeded(
          result: result,
          previousState: previousState
        )
      }

      internalLog(.monitorAggregation, "Completed successfully")
    } catch {
      internalLog(.monitorAggregation, "Failed: \(error.localizedDescription)")
    }

    // Schedule the next background task for tomorrow
    scheduleMonitorAggregationTask()
  }

  /// Calculates the next time to run the monitor aggregation (12 hours from now).
  private func nextMonitorAggregationTime() -> Date {
    Calendar.current.date(byAdding: .hour, value: 12, to: Date()) ?? Date()
  }
}
