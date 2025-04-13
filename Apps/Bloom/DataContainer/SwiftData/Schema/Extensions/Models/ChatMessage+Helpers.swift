//
//  ChatMessage+Helpers.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-13.
//

import Foundation

public extension ChatMessage {
  enum Content {
    case message(String)
    case imageData(Data)
    case richContent(Data)
  }
}

public extension ChatMessage {

  var content: Content {
    if let richContent {
      return .richContent(richContent)
    } else if let imageData {
      return .imageData(imageData)
    } else {
      return .message(message ?? "")
    }
  }
}
