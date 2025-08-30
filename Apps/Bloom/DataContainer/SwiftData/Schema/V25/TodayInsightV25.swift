//
//  TodayInsightV25.swift
//  DataContainer
//
//  Created by Assistant on 2025-08-29.
//

import SwiftData

// https://www.hackingwithswift.com/books/ios-swiftui/syncing-swiftdata-with-cloudkit
// For CloudKit sync to work, all properties must be optional or have default values, and all relationship must be optional.

extension SchemaV25 {
  @Model
  public final class TodayInsight: Identifiable, Hashable {
    public var id: String = ""
    public var title: String? = nil
    public var body: String? = nil
    public var priority: Int = 1
    
    public var content: TodayContent?
    
    public init(
      id: String = UUID().uuidString,
      title: String,
      body: String,
      priority: Int
    ) {
      self.id = id
      self.title = title
      self.body = body
      self.priority = priority
    }
  }
}