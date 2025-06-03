//
//  TypingStateTracker.swift
//  Bloom-Backend
//
//  Created by Assistant on 2025-06-02.
//

import Foundation
import BloomModel

actor TypingStateTracker {
  private var typingStates: [UserIdentifier: Bool] = [:]
  
  /// Sets the typing state for a user and returns true if the state changed
  func setTypingIfChanged(_ isTyping: Bool, for userID: UserIdentifier) -> Bool {
    let currentState = typingStates[userID] ?? false
    if currentState != isTyping {
      typingStates[userID] = isTyping
      return true
    }
    return false
  }
  
  /// Resets the typing state for a user
  func reset(for userID: UserIdentifier) {
    typingStates.removeValue(forKey: userID)
  }
  
  /// Gets the current typing state for a user
  func isTyping(for userID: UserIdentifier) -> Bool {
    return typingStates[userID] ?? false
  }
}