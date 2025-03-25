//
//  ChatMessage.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import Foundation

struct ChatMessage: Identifiable, Hashable {
  let id: String
  let message: String
  let isCurrentUser: Bool

  init(
    id: String = UUID().uuidString,
    message: String,
    isCurrentUser: Bool
  ) {
    self.id = id
    self.message = message
    self.isCurrentUser = isCurrentUser
  }
}
