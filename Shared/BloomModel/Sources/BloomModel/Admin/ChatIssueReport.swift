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
  public let state: State
  public let isAnonymous: Bool
  public let userID: UserIdentifier?
  public let userName: String?
  public let createdAt: Date
  
  public init(
    id: String,
    responseID: String,
    notes: String?,
    state: State,
    isAnonymous: Bool,
    userID: UserIdentifier?,
    userName: String?,
    createdAt: Date
  ) {
    self.id = id
    self.responseID = responseID
    self.notes = notes
    self.state = state
    self.isAnonymous = isAnonymous
    self.userID = userID
    self.userName = userName
    self.createdAt = createdAt
  }
}

extension AdminChatIssueReport {
  public enum State: String, Codable, Sendable, CaseIterable {
    case open
    case archived
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

public struct AdminArchiveChatIssueReportRequest: Codable, Sendable {
  public let reportID: String
  
  public init(reportID: String) {
    self.reportID = reportID
  }
}

public struct AdminArchiveChatIssueReportResponse: Codable, Sendable {
  public let success: Bool
  public let report: AdminChatIssueReport
  
  public init(success: Bool, report: AdminChatIssueReport) {
    self.success = success
    self.report = report
  }
}
