//
//  TodayReportResponse.swift
//  bloom-model
//
//  Created by Assistant on 2025-08-27.
//

import Foundation

public struct TodayReportResponse: Codable, Hashable, Sendable {
  public let todaysAdvice: String
  public let insights: [HealthInsight]
  public let sleepDetails: String?
  public let tonightsSleepRecommendations: String
  
  public init(
    todaysAdvice: String,
    insights: [HealthInsight],
    sleepDetails: String?,
    tonightsSleepRecommendations: String
  ) {
    self.todaysAdvice = todaysAdvice
    self.insights = insights
    self.sleepDetails = sleepDetails
    self.tonightsSleepRecommendations = tonightsSleepRecommendations
  }
}

public extension TodayReportResponse {
  struct HealthInsight: Codable, Hashable, Sendable {
    public let title: String
    public let body: String
    public let priority: Int // 1-10, where 10 is highest priority
    
    public init(
      title: String,
      body: String,
      priority: Int
    ) {
      self.title = title
      self.body = body
      self.priority = min(max(priority, 1), 10) // Ensure priority is between 1 and 10
    }
  }
}
