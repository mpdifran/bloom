//
//  MorningHealthReportV22.swift
//  Bloom
//
//  Created by Assistant on 2025-07-24.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV22 {
  @Model
  public final class MorningHealthReport: Identifiable, Hashable {
    public var id: String = ""
    public var day: Date = Date.distantPast
    public var sleepFeedback: String? = nil
    public var readinessScore: Int = 0
    public var readinessSummary: String? = nil
    public var todaysFocus: String? = nil
    
    @Relationship(deleteRule: .cascade, inverse: \MorningHealthInsight.report)
    public var insights: [MorningHealthInsight]? = []
    
    public init(
      id: String = UUID().uuidString,
      day: Date,
      sleepFeedback: String,
      readinessScore: Int,
      readinessSummary: String,
      todaysFocus: String
    ) {
      self.id = id
      self.day = day
      self.sleepFeedback = sleepFeedback
      self.readinessScore = readinessScore
      self.readinessSummary = readinessSummary
      self.todaysFocus = todaysFocus
      self.insights = []
    }
  }
}
