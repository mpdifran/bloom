//
//  ChatCellModel.swift
//  Bloom
//
//  Created by Assistant on 2025-01-29.
//

import Foundation
import DataContainer

enum ChatCellType: Equatable {
  case message(ChatMessageDTO)
  case inProgress(ChatController.InProgressMessage)
  case typingIndicator
  case statusText(String)
  case prompts
}

struct ChatCellModel: Identifiable, Equatable {
  let id: String
  let contentType: ChatCellType
}