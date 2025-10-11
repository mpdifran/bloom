//
//  TodayContentDTO.swift
//  DataContainer
//
//  Created by Assistant on 2025-01-25.
//

import Foundation

public struct TodayContentDTO: Sendable, Hashable, Codable {
  public let day: Date
  public let timestamp: Date
  public let summary: String
  public let budState: String
  public let todaysAdvice: String
  public let sleepDetails: String?
  public let tonightsSleepRecommendations: String
  public let insights: [TodayInsightDTO]
  public let periodInsight: PeriodInsightDTO?

  public init(
    day: Date,
    timestamp: Date,
    summary: String,
    budState: String,
    todaysAdvice: String,
    sleepDetails: String?,
    tonightsSleepRecommendations: String,
    insights: [TodayInsightDTO],
    periodInsight: PeriodInsightDTO? = nil
  ) {
    self.day = day
    self.timestamp = timestamp
    self.summary = summary
    self.budState = budState
    self.todaysAdvice = todaysAdvice
    self.sleepDetails = sleepDetails
    self.tonightsSleepRecommendations = tonightsSleepRecommendations
    self.insights = insights
    self.periodInsight = periodInsight
  }
}

public struct TodayInsightDTO: Sendable, Hashable, Codable {
  public let title: String
  public let body: String
  public let priority: Int

  public init(
    title: String,
    body: String,
    priority: Int
  ) {
    self.title = title
    self.body = body
    self.priority = priority
  }
}

public struct PeriodInsightDTO: Sendable, Hashable, Codable {
  public let phaseTip: String?
  public let periodForecast: String?

  public init(
    phaseTip: String?,
    periodForecast: String?
  ) {
    self.phaseTip = phaseTip
    self.periodForecast = periodForecast
  }
}