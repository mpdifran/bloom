//
//  TodayReportRequest.swift
//  bloom-model
//
//  Created by Assistant on 2025-08-27.
//

import Foundation

public struct TodayReportRequest: Codable, Hashable, Sendable {
  public let healthContext: String // JSON string containing health data
  public let currentTime: String // ISO-8601 date string
  public let timezone: String
  
  public init(
    healthContext: String,
    currentTime: String,
    timezone: String
  ) {
    self.healthContext = healthContext
    self.currentTime = currentTime
    self.timezone = timezone
  }
}
