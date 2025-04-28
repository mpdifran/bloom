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
    try decoder.decode(type, from: Data(function.arguments.utf8))
  }
}
