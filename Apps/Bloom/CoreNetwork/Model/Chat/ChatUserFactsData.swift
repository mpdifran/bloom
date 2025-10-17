//
//  ChatUserFactsData.swift
//  Bloom
//
//  Created by Claude on 2025-06-06.
//

import Foundation

public struct ChatUserFactsData: SendableNetworkModel {
  public let userFacts: [UserFact]

  public init(userFacts: [UserFact]) {
    self.userFacts = userFacts
  }
}

extension ChatUserFactsData {
  public struct UserFact: SendableNetworkModel {
    public let id: String
    public let fact: String
    public let dateAdded: Date
    public let revisitDate: Date

    public init(id: String, fact: String, dateAdded: Date, revisitDate: Date) {
      self.id = id
      self.fact = fact
      self.dateAdded = dateAdded
      self.revisitDate = revisitDate
    }
  }
}