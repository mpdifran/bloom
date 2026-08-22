//
//  ChatMessageV32.swift
//  DataContainer
//
//  Adds `sources` for web search citations.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV32 {
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

    /// Encoded `[SocketMessage.SourceRef]` - the web pages this message drew on.
    ///
    /// Stored rather than derived because a conversation is read back long after the socket
    /// message is gone, and a citation that vanishes on relaunch would leave the claim it
    /// supports uncited.
    ///
    /// Kept as `Data` rather than a relationship: sources are read and written only as a whole
    /// set, never queried across, and a child model would be three more CloudKit records per
    /// message for nothing.
    public var sources: Data? = nil

    @Attribute(.externalStorage) public var imageData: Data? = nil

    // Relationship to conversation
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
      sources: Data? = nil,
      conversation: ChatConversation? = nil
    ) {
      self.id = id
      self.isCurrentUser = isCurrentUser
      self.date = date
      self.message = message
      self.sources = sources
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
