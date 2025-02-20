//
//  AssistantDeleteThreadRequest.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation

public struct AssistantDeleteThreadRequest: Codable, Equatable, Sendable {
  public let kinds: [AssistantKind]

  public init(kinds: [AssistantKind]) {
    self.kinds = kinds
  }
}

public extension AssistantDeleteThreadRequest {
  enum AssistantKind: String, Codable, Equatable, Sendable {
    case healthCoach
  }
}
