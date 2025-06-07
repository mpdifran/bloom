//
//  SocketMessage+DeleteReminder.swift
//  bloom-model
//
//  Created by Assistant on 2025-06-07.
//

import Foundation

public extension SocketMessage {
  struct DeleteReminder: Codable, Equatable, Sendable {
    public let reminderID: String
    public let type: `Type`

    public init(reminderID: String) {
      self.reminderID = reminderID
      self.type = .deleteReminder
    }

    public enum `Type`: String, Codable, Equatable, Sendable {
      case deleteReminder = "delete-reminder"
    }
  }
}
