//
//  HealthReportController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-07-23.
//

import Foundation
import Vapor
import BloomModel

struct HealthReportController { }

extension HealthReportController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.auth(using: UserToken.self) {
        $0.group("today") {
          $0.post("insights", use: generateTodayView)
        }
        $0.group("monitor") {
          $0.post("insight", use: generateMonitorInsight)
        }
      }
    }
  }
}

private extension HealthReportController {

  @Sendable
  func generateTodayView(_ request: Request) async throws -> TodayReportResponse {
    let body = try request.content.decode(TodayReportRequest.self)
    let user = try request.auth.require(User.self)

    guard let userID = user.id else {
      throw Abort(.unauthorized)
    }

    try await request.aiUsageLimiter.checkBudget(for: userID)

    // Generate the today view response
    return try await request.healthReportService.generateTodayView(
      healthContext: body.healthContext,
      currentTime: body.currentTime,
      timezone: body.timezone,
      locale: body.locale,
      interfaceLocale: body.interfaceLocale,
      userID: userID
    )
  }

  @Sendable
  func generateMonitorInsight(_ request: Request) async throws -> MonitorInsightResponse {
    let body = try request.content.decode(MonitorInsightRequest.self)
    let user = try request.auth.require(User.self)

    guard let userID = user.id else {
      throw Abort(.unauthorized)
    }

    try await request.aiUsageLimiter.checkBudget(for: userID)

    return try await request.healthReportService.generateMonitorInsight(
      monitorType: body.monitorType,
      monitorContext: body.monitorContext,
      healthContext: body.healthContext,
      timezone: body.timezone,
      locale: body.locale,
      interfaceLocale: body.interfaceLocale,
      userID: userID
    )
  }
}
