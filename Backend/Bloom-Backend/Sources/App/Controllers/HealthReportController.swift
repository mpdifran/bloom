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
        $0.group("biological-age") {
          $0.post("calculate", use: calculateBiologicalAge)
          $0.post("request", use: requestBiologicalAge)
          $0.post("status", use: checkBiologicalAgeStatus)
        }
        $0.group("monitor") {
          $0.post("summary", use: generateMonitorSummary)
          $0.post("insight", use: generateMonitorInsight)
        }
      }
    }
  }
}

private extension HealthReportController {

  @Sendable
  func generateMorningReport(_ request: Request) async throws -> MorningHealthReportResponse {
    let body = try request.content.decode(MorningHealthReportRequest.self)
    let user = try request.auth.require(User.self)

    guard let userID = user.id else {
      throw Abort(.unauthorized)
    }

    try await request.aiUsageLimiter.checkBudget(for: userID)

    return try await request.healthReportService.generateMorningHealthReport(
      from: body.healthContext,
      userID: userID
    )
  }

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
      userID: userID
    )
  }

  @Sendable
  func calculateBiologicalAge(_ request: Request) async throws -> BiologicalAgeResponse {
    let body = try request.content.decode(BiologicalAgeRequest.self)
    let user = try request.auth.require(User.self)

    guard let userID = user.id else {
      throw Abort(.unauthorized)
    }

    try await request.aiUsageLimiter.checkBudget(for: userID)

    return try await request.healthReportService.calculateBiologicalAge(
      healthContext: body.healthContext,
      currentAge: body.currentAge,
      lastBiologicalAge: body.lastBiologicalAge,
      userID: userID
    )
  }

  @Sendable
  func requestBiologicalAge(_ request: Request) async throws -> BiologicalAgeUploadResponse {
    let body = try request.content.decode(BiologicalAgeUploadRequest.self)
    let user = try request.auth.require(User.self)

    guard let userID = user.id else {
      throw Abort(.unauthorized)
    }

    // Check if a job already exists for this user
    if let existingJob = try await request.biologicalAgeJobManager.getJob(userId: userID) {
      // If job is pending or processing, return that status
      if let status = BiologicalAgeStatus(rawValue: existingJob.status),
         (status == .pending || status == .processing) {
        return BiologicalAgeUploadResponse(status: status)
      }
    }

    // Create job in Redis
    try await request.biologicalAgeJobManager.createJob(
      userId: userID,
      healthContext: body.healthContext,
      currentAge: body.currentAge,
      lastBiologicalAge: body.lastBiologicalAge
    )

    // Trigger background processing
    Task {
      await request.biologicalAgeJobManager.processJob(
        userId: userID,
        healthReportService: request.healthReportService,
        db: request.db,
        application: request.application
      )
    }

    return BiologicalAgeUploadResponse(status: .pending)
  }

  @Sendable
  func checkBiologicalAgeStatus(_ request: Request) async throws -> BiologicalAgeStatusResponse {
    let user = try request.auth.require(User.self)

    guard let userID = user.id else {
      throw Abort(.unauthorized)
    }

    // Get job for this user
    guard let job = try await request.biologicalAgeJobManager.getJob(userId: userID) else {
      // Job not found - return notFound status
      return BiologicalAgeStatusResponse(
        status: .notFound,
        result: nil,
        errorMessage: nil
      )
    }

    // Parse result if available
    var result: BiologicalAgeResponse?
    if let resultJson = job.resultJson,
       let resultData = resultJson.data(using: .utf8) {
      result = try? JSONDecoder.bloomModel.decode(
        BiologicalAgeResponse.self,
        from: resultData
      )
    }

    // Convert string status to enum
    guard let status = BiologicalAgeStatus(rawValue: job.status) else {
      return BiologicalAgeStatusResponse(
        status: .failed,
        result: nil,
        errorMessage: "Invalid job status"
      )
    }

    return BiologicalAgeStatusResponse(
      status: status,
      result: result,
      errorMessage: job.errorMessage
    )
  }

  @Sendable
  func generateMonitorSummary(_ request: Request) async throws -> MonitorSummaryResponse {
    let body = try request.content.decode(MonitorSummaryRequest.self)
    let user = try request.auth.require(User.self)

    guard let userID = user.id else {
      throw Abort(.unauthorized)
    }

    try await request.aiUsageLimiter.checkBudget(for: userID)

    return try await request.healthReportService.generateMonitorSummary(
      monitorContext: body.monitorContext,
      healthContext: body.healthContext,
      timezone: body.timezone,
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
      userID: userID
    )
  }
}
