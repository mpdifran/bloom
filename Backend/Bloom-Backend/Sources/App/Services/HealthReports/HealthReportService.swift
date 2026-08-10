//
//  HealthReportService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-07-23.
//

import Foundation
import Vapor
import BloomModel
import OpenAIKit

final class HealthReportService: Sendable {
  private let openAIService: OpenAIService
  private let todayInsightsHistory: TodayInsightsHistory
  private let aiUsageLimiter: AIUsageLimiter

  init(openAIService: OpenAIService, todayInsightsHistory: TodayInsightsHistory, aiUsageLimiter: AIUsageLimiter) {
    self.openAIService = openAIService
    self.todayInsightsHistory = todayInsightsHistory
    self.aiUsageLimiter = aiUsageLimiter
  }

  private let modelID = ModelID.GPT5_6.luna

  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel
}

// MARK: - Public Methods

extension HealthReportService {

  func generateTodayView(
    healthContext: String,
    currentTime: String,
    timezone: String,
    userID: UserIdentifier
  ) async throws -> TodayReportResponse {

    var inputItems = [OpenAIKit.Response.InputItem]()

    inputItems.append(
      .message(
        .init(
          role: .system,
          content: [
            .text(.init(text: "Here is the user's health data from yesterday:\n\(healthContext)"))
          ]
        )
      )
    )

    inputItems.append(
      .message(
        .init(
          role: .system,
          content: [
            .text(.init(text: "Current time: \(currentTime)\nTimezone: \(timezone)"))
          ]
        )
      )
    )

    let response = try await openAIService.openAI.responses.createResponse(
      input: inputItems,
      model: modelID,
      instructions: .Prompt.todayAI,
      reasoning: .init(effort: .low, summary: .auto),
      text: OpenAIKit.Text(format: Format(type: .jsonSchema(.todayAI))),
      truncation: .auto,
      user: userID.value
    )

    await aiUsageLimiter.record(
      model: modelID,
      inputTokens: response.usage?.inputTokens ?? 0,
      outputTokens: response.usage?.outputTokens ?? 0,
      for: userID
    )

    guard let todayResponse = try response.parse(TodayReportResponse.self) else {
      throw Abort(.internalServerError, reason: "Failed to parse today report response")
    }

    return todayResponse
  }

  func generateMonitorInsight(
    monitorType: String,
    monitorContext: String,
    healthContext: String,
    timezone: String,
    userID: UserIdentifier
  ) async throws -> MonitorInsightResponse {

    var inputItems = [OpenAIKit.Response.InputItem]()

    inputItems.append(
      .message(
        .init(
          role: .system,
          content: [
            .text(.init(text: "Monitor type: \(monitorType)"))
          ]
        )
      )
    )

    inputItems.append(
      .message(
        .init(
          role: .system,
          content: [
            .text(.init(text: "Current monitor state and signals:\n\(monitorContext)"))
          ]
        )
      )
    )

    inputItems.append(
      .message(
        .init(
          role: .system,
          content: [
            .text(.init(text: "User's health baseline data:\n\(healthContext)"))
          ]
        )
      )
    )

    inputItems.append(
      .message(
        .init(
          role: .system,
          content: [
            .text(.init(text: "User's timezone: \(timezone)"))
          ]
        )
      )
    )

    let response = try await openAIService.openAI.responses.createResponse(
      input: inputItems,
      model: modelID,
      instructions: .Prompt.monitorInsight,
      reasoning: .init(effort: .low, summary: .auto),
      text: OpenAIKit.Text(format: Format(type: .jsonSchema(.monitorInsight))),
      truncation: .auto,
      user: userID.value
    )

    await aiUsageLimiter.record(
      model: modelID,
      inputTokens: response.usage?.inputTokens ?? 0,
      outputTokens: response.usage?.outputTokens ?? 0,
      for: userID
    )

    guard let monitorInsight = try response.parse(MonitorInsightResponse.self) else {
      throw Abort(.internalServerError, reason: "Failed to parse monitor insight response")
    }

    return monitorInsight
  }
}
