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

  var healthReportService: HealthReportService {
    if let service = storage[HealthReportServiceKey.self] {
      return service
    }

    let service = HealthReportService(
      openAIService: openAIService
    )

    storage[HealthReportServiceKey.self] = service
    return service
  }
}
