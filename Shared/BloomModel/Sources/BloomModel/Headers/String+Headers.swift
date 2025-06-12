//
//  String+Headers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-06-12.
//

import Foundation

public extension String {
  enum Header { }
}

public extension String.Header {
  static let version = "X-Bloom-API-Version"
  static let openAIModel = "X-Bloom-OpenAI-Model"
}
