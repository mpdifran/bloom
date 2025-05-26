//
//  SocketMessage+ResponseCompleted.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-05-26.
//

import Foundation

public extension SocketMessage {
  struct ResponseCompleted: Codable, Equatable, Sendable {
    public var type: `Type`

    public enum `Type`: String, Codable, Equatable, Sendable {
      case responseCompleted
    }

    public init() {
      self.type = .responseCompleted
    }
  }
}
