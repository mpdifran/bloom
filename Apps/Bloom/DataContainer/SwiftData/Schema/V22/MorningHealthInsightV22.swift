//
//  MorningHealthInsightV22.swift
//  Bloom
//
//  Created by Assistant on 2025-07-24.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV22 {
  @Model
  public final class MorningHealthInsight: Identifiable, Hashable {
    public var id: String = ""
    public var title: String? = nil
    public var body: String? = nil
    public var emoji: String? = nil
    public var relevanceScore: Double = 0.0
    
    public var report: MorningHealthReport?
    
    public init(
      id: String = UUID().uuidString,
      title: String,
      body: String,
      emoji: String,
      relevanceScore: Double
    ) {
      self.id = id
      self.title = title
      self.body = body
      self.emoji = emoji
      self.relevanceScore = relevanceScore
    }
  }
}
