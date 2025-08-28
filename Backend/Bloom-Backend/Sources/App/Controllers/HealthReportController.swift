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
        $0.group("morning-report") {
          $0.post("generate", use: generateMorningReport)
        }
        $0.group("today") {
          $0.post("insights", use: generateTodayView)
        }
      }
    }
  }
}

private extension HealthReportController {

  @Sendable
  func generateMorningReport(_ request: Request) async throws -> MorningHealthReportResponse {
    let body = try request.content.decode(MorningHealthReportRequest.self)

    return try await request.healthReportService.generateMorningHealthReport(from: body.healthContext)
  }

  @Sendable
  func generateTodayView(_ request: Request) async throws -> TodayReportResponse {
    let body = try request.content.decode(TodayReportRequest.self)
    
    // Generate the today view response
    return try await request.healthReportService.generateTodayView(
      healthContext: body.healthContext,
      currentTime: body.currentTime,
      timezone: body.timezone
    )
  }
}
