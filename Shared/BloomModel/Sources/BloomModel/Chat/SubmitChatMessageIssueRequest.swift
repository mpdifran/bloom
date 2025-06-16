//
//  SubmitChatMessageIssueRequest.swift
//  BloomModel
//
//  Created by Assistant on 2025-06-11.
//

import Foundation

public struct SubmitChatMessageIssueRequest: Codable, Sendable {
  public let responseID: String
  public let notes: String?
  public let isAnonymous: Bool
  public let appVersion: String?

  public init(
    responseID: String,
    notes: String?,
    isAnonymous: Bool,
    appVersion: String? = nil
  ) {
    self.responseID = responseID
    self.notes = notes
    self.isAnonymous = isAnonymous
    self.appVersion = appVersion
  }
}
