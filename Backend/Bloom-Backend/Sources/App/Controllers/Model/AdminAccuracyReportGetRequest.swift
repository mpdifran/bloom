//
//  AdminAccuracyReportGetRequest.swift
//  Bloom-Backend
//
//  Created by Haocen Jiang on 2025-02-04.
//

import Vapor

struct AdminAccuracyReportGetRequest: Content {
  let foodItemRecordID: String
  
  enum CodingKeys: String, CodingKey {
    case foodItemRecordID = "food_item_record_id"
  }
}
