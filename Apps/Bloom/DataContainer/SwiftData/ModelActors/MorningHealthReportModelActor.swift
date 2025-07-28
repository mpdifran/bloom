//
//  MorningHealthReportModelActor.swift
//  DataContainer
//
//  Created by Assistant on 2025-07-24.
//

import Foundation
import SwiftData
import BloomFoundation

@ModelActor
public final actor MorningHealthReportModelActor: SharedModelActor {

  private var context: ModelContext { modelExecutor.modelContext }
}

public extension MorningHealthReportModelActor {

  func fetchReport(for date: Date) throws -> MorningHealthReportDTO? {
    let dayStart = Calendar.current.startOfDay(for: date)
    let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
    
    let predicate = #Predicate<MorningHealthReport> { report in
      report.day >= dayStart && report.day < dayEnd
    }
    let descriptor = FetchDescriptor<MorningHealthReport>(predicate: predicate)
    guard let report = try context.fetch(descriptor).first else { return nil }
    return report.asDTO()
  }

  func deleteReport(for date: Date) throws {
    let dayStart = Calendar.current.startOfDay(for: date)
    let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
    
    let predicate = #Predicate<MorningHealthReport> { report in
      report.day >= dayStart && report.day < dayEnd
    }
    let descriptor = FetchDescriptor<MorningHealthReport>(predicate: predicate)
    let existingReports = try context.fetch(descriptor)
    
    for existingReport in existingReports {
      context.delete(existingReport)
    }
    
    try context.save()
  }

  func saveReport(
    for date: Date,
    sleepFeedback: String,
    readinessScore: Int,
    readinessSummary: String,
    todaysFocus: String,
    insights: [(title: String, body: String, emoji: String, relevanceScore: Double)]
  ) throws -> MorningHealthReportDTO {
    let dayStart = Calendar.current.startOfDay(for: date)
    let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
    
    // Check if a report already exists for this day and delete it
    let predicate = #Predicate<MorningHealthReport> { report in
      report.day >= dayStart && report.day < dayEnd
    }
    let descriptor = FetchDescriptor<MorningHealthReport>(predicate: predicate)
    let existingReports = try context.fetch(descriptor)
    
    for existingReport in existingReports {
      context.delete(existingReport)
    }
    
    // Create new report
    let report = MorningHealthReport(
      day: dayStart,
      sleepFeedback: sleepFeedback,
      readinessScore: readinessScore,
      readinessSummary: readinessSummary,
      todaysFocus: todaysFocus
    )
    
    // Add insights
    for insightData in insights {
      let insight = MorningHealthInsight(
        title: insightData.title,
        body: insightData.body,
        emoji: insightData.emoji,
        relevanceScore: insightData.relevanceScore
      )
      insight.report = report
      context.insert(insight)
    }
    
    context.insert(report)
    try context.save()
    
    return report.asDTO()
  }
}