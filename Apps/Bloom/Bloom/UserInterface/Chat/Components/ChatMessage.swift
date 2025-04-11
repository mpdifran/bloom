//
//  ChatMessage.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import SwiftUI

extension ChatMessage {
  enum Content: Hashable {
    case text(String)
    case image(UIImage)
    case goals([ProposedGoal])
  }
}

struct ChatMessage: Identifiable, Hashable {
  let id: String
  let content: Content
  let isCurrentUser: Bool

  init(
    id: String = UUID().uuidString,
    content: Content,
    isCurrentUser: Bool
  ) {
    self.id = id
    self.content = content
    self.isCurrentUser = isCurrentUser
  }
}
