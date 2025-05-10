//
//  JSONCoders+Watch.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-05-09.
//

import Foundation

// MARK: - JSONEncoder

public extension JSONEncoder {

  static let watch: JSONEncoder = {
    let encoder = JSONEncoder()

    encoder.keyEncodingStrategy = .useDefaultKeys
    encoder.dateEncodingStrategy = .iso8601

    return encoder
  }()
}

// MARK: - JSONDecoder

public extension JSONDecoder {

  static let watch: JSONDecoder = {
    let decoder = JSONDecoder()

    decoder.keyDecodingStrategy = .useDefaultKeys
    decoder.dateDecodingStrategy = .iso8601

    return decoder
  }()
}
