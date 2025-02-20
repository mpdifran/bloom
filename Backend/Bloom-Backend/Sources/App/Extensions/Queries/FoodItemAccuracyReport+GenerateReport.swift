//
//  FoodItemAccuracyReport+GenerateReport.swift
//  Bloom-Backend
//
//  Created by Haocen Jiang on 2025-02-13.
//

import BloomModel
import Vapor
import Fluent
import OpenAIKit

extension FoodItemAccuracyReport {
  enum ReportGenerationError: String, Error {
    case noFoodItemFound = "No food item record with given ID"
  }
  
  static func generateReport(
    forFoodItemRecordWithID foodItemId: FoodItemIdentifier,
    db: any Database,
    openAIService: OpenAIService,
    imageStorage: ImageStorage,
    openAIClient: OpenAIKit.Client
  ) async throws -> FoodItemAccuracyReport {
    
    async let foodItemRecord = try await FoodItemRecord.find(foodItemId.value, on: db)
    async let issueReportCount = try await FoodItemIssueReport.query(on: db).filter(\.$foodItemRecord.$id == foodItemId.value).count()
    async let recentIssueReports = try await FoodItemIssueReport.query(on: db).filter(\.$foodItemRecord.$id == foodItemId.value).limit(5).all()
    
    guard let foodItemRecord = try await foodItemRecord else {
      throw ReportGenerationError.noFoodItemFound
    }
    
    let evaluation = try await openAIService.evaluateFoodItemAccuracy(
      foodItemRecord: foodItemRecord,
      totalNumberOfIssueReports: issueReportCount,
      sampleIssueReports: recentIssueReports,
      imageStorage: imageStorage,
      openAIClient: openAIClient
    )
    
    // Create and save the accuracy report
    let accuracyReport = FoodItemAccuracyReport(
      id: UUID().uuidString,
      foodItemRecord: foodItemId.value,
      accuracyScore: Double(evaluation.score),
      evaluationNotes: evaluation.notes,
      recommendations: evaluation.recommendations
    )
    
    try await accuracyReport.save(on: db)
    
    return accuracyReport
  }
}
