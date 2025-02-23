//
//  Request+Gemini.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-23.
//

import Vapor
import GoogleGenerativeAI

extension Request {

  private struct GeminiKey: StorageKey {
    typealias Value = GeminiModelProvider
  }

  var gemini: GeminiModelProvider {
    if let modelProvider = application.storage[GeminiKey.self] {
      return modelProvider
    } else {
      let modelProvider = application.gemini
      application.storage[GeminiKey.self] = modelProvider
      return modelProvider
    }
  }
}
