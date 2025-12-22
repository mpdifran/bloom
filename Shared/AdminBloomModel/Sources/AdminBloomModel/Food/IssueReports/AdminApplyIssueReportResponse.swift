//
//  AdminApplyIssueReportResponse.swift
//  AdminBloomModel
//
//  Created by Claude on 2025-12-22.
//

import Foundation

public struct AdminApplyIssueReportResponse: Codable, Sendable {
  public let foodItemRecord: AdminFoodItemRecord

  public init(foodItemRecord: AdminFoodItemRecord) {
    self.foodItemRecord = foodItemRecord
  }
}
