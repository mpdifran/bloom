//
//  ChatConversation+Helpers.swift
//  DataContainer
//
//  Created by Assistant on 2025-10-08.
//

import Foundation

public extension ChatConversation {
  /// Returns the most recent message sent by the user in the conversation.
  /// Returns `nil` if no user messages exist.
  var latestUserMessage: ChatMessage? {
    messages?
      .filter { $0.isCurrentUser }
      .max(by: { $0.date < $1.date })
  }
}
