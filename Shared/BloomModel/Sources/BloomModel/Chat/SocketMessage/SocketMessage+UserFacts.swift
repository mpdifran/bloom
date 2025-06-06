//
//  SocketMessage+UserFacts.swift
//  bloom-model
//
//  Created by Claude on 2025-06-06.
//

import Foundation

public extension SocketMessage {
  struct CreateUserFact: Codable, Equatable, Sendable {
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
      
      // Fact is required but provide fallback
      self.fact = (try? container.decode(String.self, forKey: .fact))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "User fact"
      
      // Revisit date with fallback to 30 days from now
      self.revisitDate = (try? container.decode(Date.self, forKey: .revisitDate)) ?? Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    }
  }
  
  struct DeleteUserFact: Codable, Equatable, Sendable {
    public let factID: String
    
    public init(factID: String) {
      self.factID = factID
    }
    
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      
      // Fact ID is required but provide fallback
      self.factID = (try? container.decode(String.self, forKey: .factID))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
  }
}