//
//  TodayContentModelActor.swift
//  DataContainer
//
//  Created by Assistant on 2025-08-29.
//

import Foundation
import SwiftData
import BloomFoundation

@ModelActor
public final actor TodayContentModelActor: SharedModelActor {
  
  private var context: ModelContext { modelExecutor.modelContext }
}

public extension TodayContentModelActor {
  
  func fetchContent(for date: Date) throws -> TodayContentDTO? {
    let dayStart = Calendar.current.startOfDay(for: date)
    let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
    
    let predicate = #Predicate<SchemaV25.TodayContent> { content in
      content.day >= dayStart && content.day < dayEnd
    }
    let descriptor = FetchDescriptor<SchemaV25.TodayContent>(
      predicate: predicate,
      sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
    )
    guard let content = try context.fetch(descriptor).first else { return nil }
    return content.asDTO()
  }
  
  func deleteContent(for date: Date) throws {
    let dayStart = Calendar.current.startOfDay(for: date)
    let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
    
    let predicate = #Predicate<SchemaV25.TodayContent> { content in
      content.day >= dayStart && content.day < dayEnd
    }
    let descriptor = FetchDescriptor<SchemaV25.TodayContent>(predicate: predicate)
    let existingContent = try context.fetch(descriptor)
    
    for content in existingContent {
      context.delete(content)
    }
    
    try context.save()
  }
  
  func saveContent(
    for date: Date,
    summary: String,
    budState: String,
    todaysAdvice: String,
    sleepDetails: String?,
    tonightsSleepRecommendations: String,
    insights: [(title: String, body: String, priority: Int)]
  ) throws -> TodayContentDTO {
    let dayStart = Calendar.current.startOfDay(for: date)
    let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
    
    // Check if content already exists for this day and delete it
    let predicate = #Predicate<SchemaV25.TodayContent> { content in
      content.day >= dayStart && content.day < dayEnd
    }
    let descriptor = FetchDescriptor<SchemaV25.TodayContent>(predicate: predicate)
    let existingContent = try context.fetch(descriptor)
    
    for content in existingContent {
      context.delete(content)
    }
    
    // Create new content
    let content = SchemaV25.TodayContent(
      day: dayStart,
      timestamp: Date(),
      summary: summary,
      budState: budState,
      todaysAdvice: todaysAdvice,
      sleepDetails: sleepDetails,
      tonightsSleepRecommendations: tonightsSleepRecommendations
    )
    
    // Add insights
    for insightData in insights {
      let insight = SchemaV25.TodayInsight(
        title: insightData.title,
        body: insightData.body,
        priority: insightData.priority
      )
      insight.content = content
      context.insert(insight)
    }
    
    context.insert(content)
    try context.save()
    
    return content.asDTO()
  }
  
  func hasContentForToday() -> Bool {
    do {
      // Simply check if content exists for today's calendar day
      let content = try fetchContent(for: Date())
      return content != nil
    } catch {
      return false
    }
  }
}