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

  init(openAIService: OpenAIService) {
    self.openAIService = openAIService
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
            .text(.init(text: "Here is the user's health context:\n\(healthContext)"))
          ]
        )
      )
    )
    inputItems.append(
      .message(
        .init(
          role: .user,
          content: [
            .text(.init(text: "Generate my morning report.")) // TODO: Not sure if this is needed to illicit a response from the AI.
          ]
        )
      )
    )

    let response = try await openAIService.openAI.responses.createResponse(
      input: inputItems,
      model: modelID,
      instructions: .Prompt.morningHealthReport,
      reasoning: .init(effort: .high, summary: .auto),
      text: OpenAIKit.Text(format: Format(type: .jsonSchema(.morningHealthReport))),
      truncation: .auto
    )

    guard let report = try response.parse(MorningHealthReportResponse.self) else {
      throw Abort(.internalServerError, reason: "Failed to parse morning health report response")
    }

    return report
  }
}
