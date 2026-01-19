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

  init(openAIService: OpenAIService, todayInsightsHistory: TodayInsightsHistory) {
    self.openAIService = openAIService
    self.todayInsightsHistory = todayInsightsHistory
  }

  private let modelID = ModelID.GPT5.gpt5Mini

  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel
}

// MARK: - Public Methods

extension HealthReportService {

  func generateMorningHealthReport(
    from healthContext: String,
    userID: UserIdentifier
  ) async throws -> MorningHealthReportResponse {

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

    let response = try await openAIService.openAI.responses.createResponse(
      input: inputItems,
      model: modelID,
      instructions: .Prompt.morningHealthReport,
      reasoning: .init(effort: .low, summary: .auto),
      text: OpenAIKit.Text(format: Format(type: .jsonSchema(.morningHealthReport))),
      truncation: .auto,
      user: userID.value
    )

    guard let report = try response.parse(MorningHealthReportResponse.self) else {
      throw Abort(.internalServerError, reason: "Failed to parse morning health report response")
    }

    return report
  }

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

    guard let todayResponse = try response.parse(TodayReportResponse.self) else {
      throw Abort(.internalServerError, reason: "Failed to parse today report response")
    }

    return todayResponse
  }

  func calculateBiologicalAge(
    healthContext: String,
    currentAge: Int?,
    lastBiologicalAge: Double?,
    userID: UserIdentifier
  ) async throws -> BiologicalAgeResponse {

    var inputItems = [OpenAIKit.Response.InputItem]()

    // Build context message with health data and age information
    var contextMessage = "Here is the user's health data from the last 7 days:\n\(healthContext)"

    if let currentAge = currentAge {
      contextMessage += "\n\nThe user's current chronological age is \(currentAge) years old."
    }

    if let lastBioAge = lastBiologicalAge {
      contextMessage += "\n\nThe user's last calculated biological age was \(String(format: "%.1f", lastBioAge)) years old. Use this as a reference point to maintain consistency between calculations."
    }

    inputItems.append(
      .message(
        .init(
          role: .system,
          content: [
            .text(.init(text: contextMessage))
          ]
        )
      )
    )

    let response = try await openAIService.openAI.responses.createResponse(
      input: inputItems,
      model: modelID,
      instructions: .Prompt.biologicalAge,
      reasoning: .init(effort: .medium, summary: .auto),
      text: OpenAIKit.Text(format: Format(type: .jsonSchema(.biologicalAge))),
      truncation: .auto,
      user: userID.value
    )

    guard let biologicalAgeResponse = try response.parse(BiologicalAgeResponse.self) else {
      throw Abort(.internalServerError, reason: "Failed to parse biological age response")
    }

    return biologicalAgeResponse
  }

  func generateMonitorSummary(
    monitorContext: String,
    healthContext: String,
    timezone: String,
    userID: UserIdentifier
  ) async throws -> MonitorSummaryResponse {

    var inputItems = [OpenAIKit.Response.InputItem]()

    inputItems.append(
      .message(
        .init(
          role: .system,
          content: [
            .text(.init(text: "Here is the monitor detection data showing current health monitor states:\n\(monitorContext)"))
          ]
        )
      )
    )

    inputItems.append(
      .message(
        .init(
          role: .system,
          content: [
            .text(.init(text: "Here is the user's health baseline data for context:\n\(healthContext)"))
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
      instructions: .Prompt.monitorSummary,
      reasoning: .init(effort: .low, summary: .auto),
      text: OpenAIKit.Text(format: Format(type: .jsonSchema(.monitorSummary))),
      truncation: .auto,
      user: userID.value
    )

    guard let monitorSummary = try response.parse(MonitorSummaryResponse.self) else {
      throw Abort(.internalServerError, reason: "Failed to parse monitor summary response")
    }

    return monitorSummary
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

    guard let monitorInsight = try response.parse(MonitorInsightResponse.self) else {
      throw Abort(.internalServerError, reason: "Failed to parse monitor insight response")
    }

    return monitorInsight
  }
}
