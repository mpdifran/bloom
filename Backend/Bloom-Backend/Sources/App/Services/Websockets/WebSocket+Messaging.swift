//
//  WebSocket+Messaging.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-01.
//

import Foundation
import WebSocketKit
import BloomModel

extension WebSocket {

  func send<Content>(_ content: Content) throws where Content: Codable {
    let encoder = JSONEncoder.bloomModel
    let data = try encoder.encode(content)
    try send(data)
  }
}
