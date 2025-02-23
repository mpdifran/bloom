//
//  GeminiService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-23.
//

import Vapor
import Foundation
import BloomModel
import GoogleGenerativeAI

struct GeminiService { }

extension GeminiService {

  func estimateCalories(
    _ request: Request,
    foodImageFile: ImageFile
  ) async -> AIEstimateCaloriesResponse? {

    let model = request.gemini.flash1_5

    let imagePart = ModelContent.Part.data(
      mimetype: "image/\(foodImageFile.fileExtension)",
      foodImageFile.data
    )
    let textPart = ModelContent.Part.text(.Prompt.estimateCalories)

    do {
      let response = try await model.generateContent([imagePart, textPart])

      // Extract text response
      guard let message = response.candidates.first?.content.parts.compactMap({ part in
        if case let .text(text) = part { return text }
        return nil
      }).first else {
        request.logger.error("Gemini API response did not contain a valid text response.")
        return nil
      }

      // Clean up JSON formatting
      var cleanedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)
      if cleanedMessage.hasPrefix("```json") { cleanedMessage.removeFirst("```json".count)
      }
      if cleanedMessage.hasSuffix("```") { cleanedMessage.removeLast("```".count)
      }

      guard let jsonData = cleanedMessage.data(using: .utf8) else {
        request.logger.error("Failed to convert response string to Data.")
        return nil
      }

      // Decode JSON into AIEstimateCaloriesResponse
      let decoder = JSONDecoder()
      decoder.keyDecodingStrategy = .convertFromSnakeCase

      do {
        return try decoder.decode(AIEstimateCaloriesResponse.self, from: jsonData)
      } catch {
        request.logger.error("Failed to decode Gemini response: \(error.localizedDescription)")
        request.logger.error("Raw response: \(cleanedMessage)")
        return nil
      }
    } catch {
      request.logger.error(error)
      return nil
    }
  }
}
