//
//  Socket+Error.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-01.
//

public extension SocketMessage {
  struct Error: Codable, Equatable, Sendable {
    public let errorMessage: String

    public init(errorMessage: String) {
      self.errorMessage = errorMessage
    }
  }
}
