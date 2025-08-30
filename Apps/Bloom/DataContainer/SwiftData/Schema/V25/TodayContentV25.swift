//
//  TodayContentV25.swift
//  DataContainer
//
//  Created by Assistant on 2025-08-29.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV25 {
  @Model
  public final class TodayContent: Identifiable, Hashable {
    public var id: String = ""
    public var day: Date = Date.distantPast
    public var timestamp: Date = Date.distantPast
    public var summary: String? = nil
    public var budState: String? = nil
    public var todaysAdvice: String? = nil
    public var sleepDetails: String? = nil
    public var tonightsSleepRecommendations: String? = nil
    
    @Relationship(deleteRule: .cascade, inverse: \TodayInsight.content)
    public var insights: [TodayInsight]? = []
    
    public init(
      id: String = UUID().uuidString,
      day: Date,
      timestamp: Date,
      summary: String,
      budState: String,
      todaysAdvice: String,
      sleepDetails: String?,
      tonightsSleepRecommendations: String
    ) {
      self.id = id
      self.day = day
      self.timestamp = timestamp
      self.summary = summary
      self.budState = budState
      self.todaysAdvice = todaysAdvice
      self.sleepDetails = sleepDetails
      self.tonightsSleepRecommendations = tonightsSleepRecommendations
      self.insights = []
    }
  }
}