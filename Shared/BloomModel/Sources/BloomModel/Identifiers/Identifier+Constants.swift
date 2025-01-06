//
//  Identifier+Constants.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2024-12-01.
//

import Foundation

public struct UserIdentifier: Codable, Sendable, Hashable {
  public let value: String

  public init() {
    self.init(UUID().uuidString)
  }

  public init(_ value: String) {
    self.value = value
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.value = try container.decode(String.self)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}

public struct AuthToken: Codable, Sendable, Hashable {
  public let value: String

  public init() {
    self.init(UUID().uuidString)
  }

  public init(_ value: String) {
    self.value = value
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    self.value = try container.decode(String.self)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(value)
  }
}
