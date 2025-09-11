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

  private let modelID = ModelID.OSeries.o4Mini

  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel
}

// MARK: - Public Methods

extension HealthReportService {

  func generateMorningHealthReport(from healthContext: String) async throws -> MorningHealthReportResponse {

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
      truncation: .auto
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
      truncation: .auto
    )

    guard let todayResponse = try response.parse(TodayReportResponse.self) else {
      throw Abort(.internalServerError, reason: "Failed to parse today report response")
    }

    return todayResponse
  }
}
