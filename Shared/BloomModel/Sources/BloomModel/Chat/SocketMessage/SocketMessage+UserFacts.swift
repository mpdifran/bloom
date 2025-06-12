//
//  SocketMessage+UserFacts.swift
//  bloom-model
//
//  Created by Claude on 2025-06-06.
//

import Foundation

public extension SocketMessage {
  struct CreateUserFacts: Codable, Hashable, Sendable {
    public let facts: [UserFactInput]
    public let type: `Type`

    public init(facts: [UserFactInput]) {
      self.facts = facts
      self.type = .createUserFacts
    }

    public enum `Type`: String, Codable, Hashable, Sendable {
      case createUserFacts
    }
  }
}

public extension SocketMessage.CreateUserFacts {
  struct UserFactInput: Codable, Hashable, Sendable {
    public let fact: String
    public let revisitDate: Date

    public init(
      fact: String,
      revisitDate: Date
    ) {
      self.fact = fact
      self.revisitDate = revisitDate
    }

    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      self.fact = try container.decode(String.self, forKey: .fact).trimmingCharacters(in: .whitespacesAndNewlines)

      // Revisit date with fallback to 30 days from now
      self.revisitDate = (try? container.decode(Date.self, forKey: .revisitDate)) ?? Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    }
  }
}

public extension SocketMessage {
  struct DeleteUserFacts: Codable, Hashable, Sendable {
    public let facts: [DeletedFact]
    public let type: `Type`

    public init(facts: [DeletedFact]) {
      self.facts = facts
      self.type = .deletedUserFacts
    }

    public enum `Type`: String, Codable, Hashable, Sendable {
      case deletedUserFacts
    }
  }
}

public extension SocketMessage.DeleteUserFacts {
  struct DeletedFact: Codable, Hashable, Sendable {
    public let id: String
    public let fact: String

    public init(id: String, fact: String) {
      self.id = id
      self.fact = fact
    }
  }
}
