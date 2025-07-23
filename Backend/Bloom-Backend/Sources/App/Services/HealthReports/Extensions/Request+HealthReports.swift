//
//  Request+HealthReports.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-07-23.
//

import Vapor

extension Request {

  var healthReportService: HealthReportService {
    application.healthReportService
  }
}
