//
//  ChatMessageV27.swift
//  DataContainer
//
//  Created by Assistant on 2025-10-08.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV27 {
  @Model
  public final class ChatMessage: Identifiable, Hashable {
    public var id: String = ""
    public var isCurrentUser: Bool = true
    public var date: Date = Date.distantPast
    public var message: String? = nil
    public var richContent: Data? = nil
    public var dbID: String? = nil
    public var hasPerformedAction: Bool = false
    public var responseID: String? = nil
    public var requestID: String? = nil

    @Attribute(.externalStorage) public var imageData: Data? = nil

    // New relationship to conversation
    public var conversation: ChatConversation? = nil

    public init(
      id: String = UUID().uuidString,
      isCurrentUser: Bool,
      date: Date = .now,
      message: String,
      dbID: String? = nil,
      hasPerformedAction: Bool = false,
      responseID: String? = nil,
      requestID: String? = nil,
      conversation: ChatConversation? = nil
    ) {
      self.id = id
      self.isCurrentUser = isCurrentUser
      self.date = date
      self.message = message
      self.richContent = nil
      self.imageData = nil
      self.dbID = dbID
      self.hasPerformedAction = hasPerformedAction
      self.responseID = responseID
      self.requestID = requestID
      self.conversation = conversation
    }

    public init(
      id: String = UUID().uuidString,
      isCurrentUser: Bool,
      date: Date = .now,
      richContent: Data,
      dbID: String? = nil,
      hasPerformedAction: Bool = false,
      responseID: String? = nil,
      requestID: String? = nil,
      conversation: ChatConversation? = nil
    ) {
      self.id = id
      self.isCurrentUser = isCurrentUser
      self.date = date
      self.message = nil
      self.richContent = richContent
      self.imageData = nil
      self.dbID = dbID
      self.hasPerformedAction = hasPerformedAction
      self.responseID = responseID
      self.requestID = requestID
      self.conversation = conversation
    }

    public init(
      id: String = UUID().uuidString,
      isCurrentUser: Bool,
      date: Date = .now,
      imageData: Data,
      dbID: String? = nil,
      hasPerformedAction: Bool = false,
      responseID: String? = nil,
      requestID: String? = nil,
      conversation: ChatConversation? = nil
    ) {
      self.id = id
      self.isCurrentUser = isCurrentUser
      self.date = date
      self.message = nil
      self.richContent = nil
      self.imageData = imageData
      self.dbID = dbID
      self.hasPerformedAction = hasPerformedAction
      self.responseID = responseID
      self.requestID = requestID
      self.conversation = conversation
    }
  }
}
