//
//  Run.ToolCall+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-02.
//

import Vapor
import Foundation
import OpenAIKit

extension Run.ToolCall {

  func decodeArguments<T: Decodable>(type: T.Type, using decoder: JSONDecoder) throws -> T {
    guard let data = function.arguments.data(using: .utf8) else { throw Abort(.badRequest) }

    return try decoder.decode(type, from: data)
  }
}
