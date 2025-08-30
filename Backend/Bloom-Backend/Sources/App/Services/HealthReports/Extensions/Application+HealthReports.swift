//
//  Application+HealthReports.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-07-23.
//

import Vapor

extension Application {

  private struct HealthReportServiceKey: StorageKey {
    typealias Value = HealthReportService
  }
  
  private struct TodayInsightsHistoryKey: StorageKey {
    typealias Value = TodayInsightsHistory
  }

  var todayInsightsHistory: TodayInsightsHistory {
    if let history = storage[TodayInsightsHistoryKey.self] {
      return history
    }

    let history = TodayInsightsHistory(
      redis: redis,
      logger: logger
    )

    storage[TodayInsightsHistoryKey.self] = history
    return history
  }

  var healthReportService: HealthReportService {
    if let service = storage[HealthReportServiceKey.self] {
      return service
    }

    let service = HealthReportService(
      openAIService: openAIService,
      todayInsightsHistory: todayInsightsHistory
    )

    storage[HealthReportServiceKey.self] = service
    return service
  }
}
