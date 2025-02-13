//
//  AdminRegenerateAccuracyReportRequest.swift
//  admin-bloom-model
//
//  Created by Haocen Jiang on 2025-02-09.
//

import BloomModel
import Foundation

public struct AdminRegenerateAccuracyReportRequest: Codable, Sendable {
  public let foodItemRecordID: FoodItemIdentifier
  
  public init(foodItemRecordID: FoodItemIdentifier) {
    self.foodItemRecordID = foodItemRecordID
  }
}
