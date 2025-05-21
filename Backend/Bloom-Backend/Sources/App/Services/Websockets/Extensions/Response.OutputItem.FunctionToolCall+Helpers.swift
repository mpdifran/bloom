//
//  Response.OutputItem.FunctionToolCall+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-20.
//

import Foundation
import OpenAIKit

extension Response.OutputItem.FunctionToolCall {

  func decodeArguments<T: Decodable>(type: T.Type, using decoder: JSONDecoder) throws -> T {
    try decoder.decode(type, from: Data(arguments.utf8))
  }
}
