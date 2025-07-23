//
//  MorningHealthReport.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-07-23.
//

public struct MorningHealthReport: Codable, Hashable, Sendable {
  public let sleepFeedback: String
  public let insights: [Insight]
  public let notificationTitle: String
  public let notificationBody: String
}

public extension MorningHealthReport {
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
