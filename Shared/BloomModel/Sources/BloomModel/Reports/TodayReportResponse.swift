//
//  TodayReportResponse.swift
//  bloom-model
//
//  Created by Assistant on 2025-08-27.
//

import Foundation

public struct TodayReportResponse: Codable, Hashable, Sendable {
  public let summary: String
  public let budState: BudState
  public let todaysAdvice: String
  public let insights: [HealthInsight]
  public let sleepDetails: String?
  public let tonightsSleepRecommendations: String
  public let windDownStartHour: Int?
  public let windDownStartMinute: Int?
  public let windDownEndHour: Int?
  public let windDownEndMinute: Int?
  public let periodInsight: PeriodPhaseInsight?

  public init(
    summary: String,
    budState: BudState,
    todaysAdvice: String,
    insights: [HealthInsight],
    sleepDetails: String?,
    tonightsSleepRecommendations: String,
    windDownStartHour: Int? = nil,
    windDownStartMinute: Int? = nil,
    windDownEndHour: Int? = nil,
    windDownEndMinute: Int? = nil,
    periodInsight: PeriodPhaseInsight? = nil
  ) {
    self.summary = summary
    self.budState = budState
    self.todaysAdvice = todaysAdvice
    self.insights = insights
    self.sleepDetails = sleepDetails
    self.tonightsSleepRecommendations = tonightsSleepRecommendations
    self.windDownStartHour = windDownStartHour
    self.windDownStartMinute = windDownStartMinute
    self.windDownEndHour = windDownEndHour
    self.windDownEndMinute = windDownEndMinute
    self.periodInsight = periodInsight
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

public extension TodayReportResponse {
  struct PeriodPhaseInsight: Codable, Hashable, Sendable {
    public let phaseTip: String?
    public let periodForecast: String?

    public init(phaseTip: String?, periodForecast: String?) {
      self.phaseTip = phaseTip
      self.periodForecast = periodForecast
    }
  }
}

public extension TodayReportResponse {
  enum BudState: String, Codable, Hashable, Sendable, CaseIterable {
    case groggy
    case sleepy
    case eatingSalad
    case holdingSmoothie
    case holdingTrophy
    case workingOut
    case stressed
    case proudCoach
    case superhero
    case running
    case strengthTraining
    case yoga
    case bicycleRiding
  }
}
