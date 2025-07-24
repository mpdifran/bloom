//
//  MorningHealthReportResponse.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-07-23.
//

public struct MorningHealthReportResponse: Codable, Hashable, Sendable {
  public let sleepFeedback: String
  public let insights: [Insight]
  public let notificationTitle: String
  public let notificationBody: String
  public let readinessScore: Int
  public let readinessSummary: String
  public let todaysFocus: String

  public init(
    sleepFeedback: String,
    insights: [Insight],
    notificationTitle: String,
    notificationBody: String,
    readinessScore: Int,
    readinessSummary: String,
    todaysFocus: String
  ) {
    self.sleepFeedback = sleepFeedback
    self.insights = insights
    self.notificationTitle = notificationTitle
    self.notificationBody = notificationBody
    self.readinessScore = readinessScore
    self.readinessSummary = readinessSummary
    self.todaysFocus = todaysFocus
  }
}

public extension MorningHealthReportResponse {
  struct Insight: Codable, Hashable, Sendable {
    public let title: String
    public let body: String
    public let emoji: String
    public let relevanceScore: Double

    public init(
      title: String,
      body: String,
      emoji: String,
      relevanceScore: Double
    ) {
      self.title = title
      self.body = body
      self.emoji = emoji
      self.relevanceScore = relevanceScore
    }
  }
}
