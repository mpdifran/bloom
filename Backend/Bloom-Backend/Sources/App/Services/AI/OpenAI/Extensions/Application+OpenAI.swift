//
//  Application+OpenAI.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-10.
//

import Vapor
import OpenAIKit

extension Application {
  public var openAI: OpenAIKit.Client {
    guard let apiKey = Environment.get("OPENAI_API_KEY") else {
      fatalError("OPENAI_API_KEY env var required")
    }
    
    let organization = Environment.get("OPENAI_ORGANIZATION")
    
    let configuration = Configuration(
      apiKey: apiKey,
      organization: organization
    )
    
    return OpenAIKit.Client(
      httpClient: self.http.client.shared,
      configuration: configuration
    )
  }

  public var gemini: OpenAIKit.Client {
    guard let apiKey = Environment.get("GEMINI_API_KEY") else {
      fatalError("GEMINI_API_KEY env var required")
    }

    let configuration = Configuration(
      apiKey: apiKey,
      api: API(
        scheme: .https,
        host: "generativelanguage.googleapis.com",
        pathPrefix: "/v1beta/openai"
      )
    )

    return OpenAIKit.Client(
      httpClient: self.http.client.shared,
      configuration: configuration
    )
  }
}
