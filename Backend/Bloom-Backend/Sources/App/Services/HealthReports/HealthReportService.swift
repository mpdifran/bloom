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
    chronologicalAge: Int,
    previousBiologicalAge: Double? = nil,
    previousPositiveFactors: [String] = [],
    previousNegativeFactors: [String] = [],
    userID: UserIdentifier
  ) async throws -> BiologicalAgeResponse {

    var inputItems = [OpenAIKit.Response.InputItem]()

    inputItems.append(
      .message(
        .init(
          role: .system,
          content: [
            .text(.init(text: "Here is the user's health data:\n\(healthContext)"))
          ]
        )
      )
    )

    var contextText = "User's chronological age: \(chronologicalAge)"
    if let previousAge = previousBiologicalAge {
      contextText += "\nPrevious biological age: \(previousAge)"
    }
    if !previousPositiveFactors.isEmpty {
      contextText += "\nPrevious positive factors: \(previousPositiveFactors.joined(separator: ", "))"
    }
    if !previousNegativeFactors.isEmpty {
      contextText += "\nPrevious negative factors: \(previousNegativeFactors.joined(separator: ", "))"
    }

    inputItems.append(
      .message(
        .init(
          role: .system,
          content: [
            .text(.init(text: contextText))
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
}
