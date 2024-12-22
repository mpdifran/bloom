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
}

public struct AuthToken: Codable, Sendable, Hashable {
  public let value: String

  public init() {
    self.init(UUID().uuidString)
  }

  public init(_ value: String) {
    self.value = value
  }
}
