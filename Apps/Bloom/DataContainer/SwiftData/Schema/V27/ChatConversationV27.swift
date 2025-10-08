//
//  ChatConversationV27.swift
//  DataContainer
//
//  Created by Assistant on 2025-10-08.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV27 {
  @Model
  public final class ChatConversation: Identifiable, Hashable {
    public var id: String = ""
    public var name: String = ""
    public var lastMessageID: String? = nil
    public var createdDate: Date = Date.distantPast
    public var updatedAt: Date = Date.distantPast

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.conversation)
    public var messages: [ChatMessage]? = []

    public init(
      id: String = UUID().uuidString,
      name: String,
      lastMessageID: String? = nil,
      createdDate: Date = .now,
      updatedAt: Date = .now
    ) {
      self.id = id
      self.name = name
      self.lastMessageID = lastMessageID
      self.createdDate = createdDate
      self.updatedAt = updatedAt
      self.messages = []
    }
  }
}
