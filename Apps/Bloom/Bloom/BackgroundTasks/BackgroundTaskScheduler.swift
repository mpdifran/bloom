//
//  BackgroundTaskScheduler.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-12.
//

import Foundation
import BackgroundTasks

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
      // Calculate today's metrics
      try await MonitorCalculator.shared.calculateMetricsForDate(Date())
      print("Monitor aggregation completed successfully")
    } catch {
      print("Monitor aggregation failed: \(error.localizedDescription)")
    }

    // Schedule the next background task for tomorrow
    scheduleMonitorAggregationTask()
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
