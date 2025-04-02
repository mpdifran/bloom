//
//  Request+OpenAI.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Vapor
@preconcurrency import OpenAIKit

extension Request {

  var openAI: OpenAIKit.Client {
    application.openAI
  }

  var gemini: OpenAIKit.Client {
    application.gemini
  }

  var openAIService: OpenAIService {
    application.openAIService
  }

  var openAIAssistantService: OpenAIAssistantService {
    application.openAIAssistantService(db: db)
  }

  var openAIAssistantProvider: OpenAIAssistantProvider {
    application.openAIAssistantProvider(db: db)
  }
}
