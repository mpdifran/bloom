//
//  JSONEncoder+StringJSON.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-06-24.
//

import Foundation

extension JSONEncoder {

  func encodeToString<T>(_ value: T) throws -> String? where T: Encodable {
    let data = try encode(value)
    return String(data: data, encoding: .utf8)
  }
}
