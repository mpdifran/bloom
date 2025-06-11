//
//  ChatIssueReport.swift
//  BloomModel
//
//  Created by Mark DiFranco on 2025-06-11.
//

import Foundation

public struct AdminChatIssueReport: Codable, Sendable, Identifiable, Hashable {
  public let id: String
  public let responseID: String
  public let notes: String?
  public let isAnonymous: Bool
  public let userID: UserIdentifier?
  public let userName: String?
  public let createdAt: Date
  
  public init(
    id: String,
    responseID: String,
    notes: String?,
    isAnonymous: Bool,
    userID: UserIdentifier?,
    userName: String?,
    createdAt: Date
  ) {
    self.id = id
    self.responseID = responseID
    self.notes = notes
    self.isAnonymous = isAnonymous
    self.userID = userID
    self.userName = userName
    self.createdAt = createdAt
  }
}

public struct AdminChatIssueReportsResponse: Codable, Sendable {
  public let reports: [AdminChatIssueReport]
  public let totalCount: Int
  
  public init(reports: [AdminChatIssueReport], totalCount: Int) {
    self.reports = reports
    self.totalCount = totalCount
  }
}

public struct AdminChatMessage: Codable, Sendable, Identifiable {
  public let id: String
  public let role: String // "user" or "assistant"
  public let content: String?
  public let imageFileID: String?
  public let timestamp: Date?
  public let metadata: [String: String]?
  
  public init(
    id: String,
    role: String,
    content: String?,
    imageFileID: String? = nil,
    timestamp: Date? = nil,
    metadata: [String: String]? = nil
  ) {
    self.id = id
    self.role = role
    self.content = content
    self.imageFileID = imageFileID
    self.timestamp = timestamp
    self.metadata = metadata
  }
}

public struct AdminChatIssueReportMessagesResponse: Codable, Sendable {
  public let reportID: String
  public let messages: [AdminChatMessage]
  
  public init(reportID: String, messages: [AdminChatMessage]) {
    self.reportID = reportID
    self.messages = messages
  }
}
