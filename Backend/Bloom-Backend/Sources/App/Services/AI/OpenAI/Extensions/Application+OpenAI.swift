//
//  Application+OpenAI.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Vapor
import OpenAIKit
import Fluent

extension Application {
  private struct OpenAIKey: StorageKey {
    typealias Value = OpenAIKit.Client
  }

  public var openAI: OpenAIKit.Client {
    if let client = storage[OpenAIKey.self] {
      return client
    }

    guard let apiKey = Environment.get("OPENAI_API_KEY") else {
      fatalError("OPENAI_API_KEY env var required")
    }
    
    let organization = Environment.get("OPENAI_ORGANIZATION")
    
    let configuration = Configuration(
      apiKey: apiKey,
      organization: organization
    )
    let client = OpenAIKit.Client(
      httpClient: self.http.client.shared,
      configuration: configuration
    )
    storage[OpenAIKey.self] = client

    return client
  }
}

extension Application {

  private struct OpenAIServiceKey: StorageKey {
    typealias Value = OpenAIService
  }

  var openAIService: OpenAIService {
    if let service = storage[OpenAIServiceKey.self] {
      return service
    }

    let service = OpenAIService(
      openAI: openAI,
      imageStorage: imageStorage,
      logger: logger,
      aiUsageLimiter: aiUsageLimiter
    )
    storage[OpenAIServiceKey.self] = service
    return service
  }
}

extension Application {

  func openAIAssistantService(db: any Database) -> OpenAIAssistantService {
    OpenAIAssistantService(
      openAI: openAI,
      db: db,
      assistantProvider: openAIAssistantProvider(db: db)
    )
  }

  func openAIAssistantProvider(db: any Database) -> OpenAIAssistantProvider {
    OpenAIAssistantProvider(
      db: db,
      openAI: openAI,
      logger: logger
    )
  }
}
