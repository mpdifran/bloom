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
  public let createdAt: Date
  
  public init(
    id: String,
    responseID: String,
    notes: String?,
    isAnonymous: Bool,
    userID: UserIdentifier?,
    createdAt: Date
  ) {
    self.id = id
    self.responseID = responseID
    self.notes = notes
    self.isAnonymous = isAnonymous
    self.userID = userID
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
