//
//  ChatUserFactsData.swift
//  Bloom
//
//  Created by Claude on 2025-06-06.
//

import Foundation

struct ChatUserFactsData: SendableNetworkModel {
  let userFacts: [UserFact]
}

extension ChatUserFactsData {
  struct UserFact: SendableNetworkModel {
    let id: String
    let fact: String
    let dateAdded: Date
    let revisitDate: Date
  }
}