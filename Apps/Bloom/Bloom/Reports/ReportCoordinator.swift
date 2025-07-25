//
//  ReportCoordinator.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-06.
//

import SwiftUI
import CoreHealth
import DataContainer
import BloomModel
import TelemetryDeck

private extension String {
  static let lastMorningReportNotificationDate = "ReportCoordinator.lastMorningReportNotificationDate"
}

final actor ReportCoordinator {
  static let shared = ReportCoordinator()

  private var lastMorningReportNotificationDate: Date? {
    didSet {
      UserDefaults.group.set(lastMorningReportNotificationDate, forKey: .lastMorningReportNotificationDate)
    }
  }
  
  private var isGeneratingReport = false

  private init() {
    if let date = UserDefaults.group.object(forKey: .lastMorningReportNotificationDate) as? Date {
      self.lastMorningReportNotificationDate = date
    }
  }
}

extension ReportCoordinator {

  func didDetectWakeUp(sleepAnalysis: SleepAnalysis? = nil) async {
    guard await ReportCoordinatorViewModel.shared.showMorningReportOnWakeUp else { return }

    // Check if we already sent a notification today
    let shouldSendNotification: Bool
    if let lastMorningReportNotificationDate {
      shouldSendNotification = !Calendar.current.isDateInToday(lastMorningReportNotificationDate)
    } else {
      shouldSendNotification = true
    }

    await generateAndStoreMorningReport(shouldSendNotification: shouldSendNotification)

    if shouldSendNotification {
      lastMorningReportNotificationDate = .now
    }
  }

  func clearLastNotificationDate() {
    lastMorningReportNotificationDate = nil
  }
  
  var isLoadingReport: Bool {
    isGeneratingReport
  }
  
  func requestMorningReport() async {
    guard !isGeneratingReport else { return }
    await generateAndStoreMorningReport(shouldSendNotification: false)
  }

  private func generateAndStoreMorningReport(shouldSendNotification: Bool) async {
    isGeneratingReport = true
    await MainActor.run {
      ReportCoordinatorViewModel.shared.isLoadingMorningReport = true
    }
    
    defer { 
      isGeneratingReport = false
      Task { @MainActor in
        ReportCoordinatorViewModel.shared.isLoadingMorningReport = false
      }
    }
    
    do {
      let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
      let today = Date()
      let reportModelActor = MorningHealthReportModelActor.standard()

      // Check if we already have a report for today
      if let existingReport = try await reportModelActor.fetchReport(for: today) {
        // Send notification using existing report data only if we should
        if shouldSendNotification {
          await NotificationManager.shared.sendGoodMorningNotification(
            title: "Morning Report",
            message: existingReport.sleepFeedback
          )
        }
        return
      }

      // Generate health context for yesterday
      let healthContext = try await DayReviewCalculator.shared.calculateDayReviewHealthDataString(for: yesterday)

      // Create request and call API
      let request = MorningHealthReportRequest(healthContext: healthContext)
      let response = try await NetworkRequester.shared.getMorningHealthReport(request: request)

      // Store the report in SwiftData using today's date as the key
      let insights = response.insights.map { insight in
        (title: insight.title, body: insight.body, emoji: insight.emoji, relevanceScore: insight.relevanceScore)
      }
      let _ = try await reportModelActor.saveReport(
        for: today,
        sleepFeedback: response.sleepFeedback,
        readinessScore: response.readinessScore,
        readinessSummary: response.readinessSummary,
        todaysFocus: response.todaysFocus,
        insights: insights
      )

      TelemetryDeck.signal("Generated Morning Report")

      // Send notification using response data only if we should
      if shouldSendNotification {
        await NotificationManager.shared.sendGoodMorningNotification(
          title: response.notificationTitle,
          message: response.notificationBody
        )
      }

    } catch {
      print(error)
      // Fallback to basic notification if API fails, but only if we should send one
      if shouldSendNotification {
        await NotificationManager.shared.sendGoodMorningNotification(
          title: "Morning Report",
          message: "Your morning report is ready!"
        )
      }
    }
  }
}
