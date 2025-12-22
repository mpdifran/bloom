//
//  AdminFoodItemIssueReportsResponse.swift
//  AdminBloomModel
//
//  Created by Claude on 2025-12-22.
//

import Foundation

public struct AdminFoodItemIssueReportsResponse: Codable, Sendable {
  public let issueReports: [AdminFoodItemIssueReport]

  public init(issueReports: [AdminFoodItemIssueReport]) {
    self.issueReports = issueReports
  }
}
