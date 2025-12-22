//
//  AdminApplyIssueReportRequest.swift
//  AdminBloomModel
//
//  Created by Claude on 2025-12-22.
//

import BloomModel
import Foundation

public struct AdminApplyIssueReportRequest: Codable, Sendable {
  public let issueReportID: String
  public let foodItemRecordID: FoodItemIdentifier
  public let fieldsToApply: [String]

  public init(
    issueReportID: String,
    foodItemRecordID: FoodItemIdentifier,
    fieldsToApply: [String]
  ) {
    self.issueReportID = issueReportID
    self.foodItemRecordID = foodItemRecordID
    self.fieldsToApply = fieldsToApply
  }
}
