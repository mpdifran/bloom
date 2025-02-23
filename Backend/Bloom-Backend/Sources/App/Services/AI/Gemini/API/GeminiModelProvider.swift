//
//  GeminiModelProvider.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-23.
//

import Foundation
import Vapor
@preconcurrency import GoogleGenerativeAI

struct GeminiModelProvider: Sendable {
  let flash1_5: GenerativeModel
  let flash2_0: GenerativeModel

  init() {
    guard let apiKey = Environment.get("GEMINI_API_KEY") else {
      fatalError("GEMINI_API_KEY env var required")
    }

    self.flash1_5 = GenerativeModel(name: "gemini-1.5-flash-latest", apiKey: apiKey)
    self.flash2_0 = GenerativeModel(name: "gemini-2.0-flash", apiKey: apiKey)
  }
}
