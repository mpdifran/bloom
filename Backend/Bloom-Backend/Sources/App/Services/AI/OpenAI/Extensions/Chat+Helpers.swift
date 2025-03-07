//
//  Chat+Helpers.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-03-03.
//

import Foundation
import OpenAIKit

extension Chat {

  func parse<T: Codable>(_ type: T.Type) throws -> T? {
    guard var message = choices.first?.message.content.first?.text else { return nil }

    if message.hasPrefix("```json") {
      message.removeFirst("```json".count)
    }
    if message.hasPrefix("```") {
      message.removeFirst("```".count)
    }
    if message.hasSuffix("```") {
      message.removeLast("```".count)
    }
    message = message.trimmingCharacters(in: .whitespacesAndNewlines)

    message = message.replacingOccurrences(of: "\\'", with: "'")

    guard let data = message.data(using: .utf8) else { return nil }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase

    return try decoder.decode(type, from: data)
  }
}
