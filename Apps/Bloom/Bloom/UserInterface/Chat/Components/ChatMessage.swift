//
//  ChatMessage.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import SwiftUI

struct ChatMessage: Identifiable, Hashable {
  let id: String
  let message: String
  let image: UIImage?
  let isCurrentUser: Bool

  init(
    id: String = UUID().uuidString,
    message: String,
    image: UIImage?,
    isCurrentUser: Bool
  ) {
    self.id = id
    self.message = message
    self.image = image
    self.isCurrentUser = isCurrentUser
  }
}
