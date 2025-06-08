//
//  SocketMessage+UserFacts.swift
//  bloom-model
//
//  Created by Claude on 2025-06-06.
//

import Foundation

public extension SocketMessage {
  struct CreateUserFacts: Codable, Equatable, Sendable {
    public let facts: [UserFactInput]
    
    public struct UserFactInput: Codable, Equatable, Sendable {
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
        
        // Fact is required
        self.fact = try container.decode(String.self, forKey: .fact).trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Revisit date with fallback to 30 days from now
        self.revisitDate = (try? container.decode(Date.self, forKey: .revisitDate)) ?? Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
      }
    }
    
    public init(facts: [UserFactInput]) {
      self.facts = facts
    }
    
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)

      if let facts = try? container.decode([UserFactInput].self, forKey: .facts) {
        self.facts = facts
      } else {
        self.facts = []
      }
    }
  }
  
  struct DeleteUserFacts: Codable, Equatable, Sendable {
    public let facts: [DeletedFact]
    
    public struct DeletedFact: Codable, Equatable, Sendable {
      public let id: String
      public let fact: String
      
      public init(id: String, fact: String) {
        self.id = id
        self.fact = fact
      }
    }
    
    public init(facts: [DeletedFact]) {
      self.facts = facts
    }
    
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      
      if let facts = try? container.decode([DeletedFact].self, forKey: .facts) {
        self.facts = facts
      } else {
        self.facts = []
      }
    }
  }
}
