//
//  Application+Gemini.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-23.
//

import Vapor
import GoogleGenerativeAI

extension Application {
  var gemini: GeminiModelProvider {
    GeminiModelProvider()
  }
}
