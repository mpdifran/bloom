//
//  FoodItemRecordAccuracyJob.swift
//  Bloom-Backend
//
//  Created by Haocen Jiang on 2025-02-12.
//

import BloomModel
import Vapor
import Fluent
import SQLKit
import VaporCron

struct FoodItemRecordAccuracyJob: AsyncVaporCronSchedulable {
  typealias T = Void
  
  // Runs at 7am every day
  static var expression: String { "0 7 * * *" }
  
  static func task(on application: Application) async throws {
    guard let sqlDatabase = application.db as? SQLDatabase else { return }
  
    // Default batch size is 5 if not set in environment
    let batchSize = Environment.get("ACCURACY_REPORT_JOB_BATCH_SIZE").flatMap(Int.init) ?? 5
    let openAIService = OpenAIService()
    
    // Step 1: Find food facts that either have no report or an outdated report
    // This query finds food items that either:
    // 1. Have never had an accuracy report generated (no matching record in food_item_accuracy_reports)
    // 2. Its latest accuracy report is older than 30 days
    // Results are limited by the configured batch size to prevent processing too many items at once
    let foodRecordsToUpdate = try await sqlDatabase.raw("""
    SELECT fi.id
    FROM food_item_records fi
    LEFT JOIN (
        SELECT food_item_record_id, MAX(created_at) AS latest_report_created_at
        FROM food_item_accuracy_reports
        GROUP BY food_item_record_id
    ) latest_reports ON fi.id = latest_reports.food_item_record_id
    WHERE latest_reports.food_item_record_id IS NULL
       OR latest_reports.latest_report_created_at < NOW() - INTERVAL '30 days'
    LIMIT \(bind: batchSize);
    """).all()
    
    application.logger.info("Found \(foodRecordsToUpdate.count) food facts to update.")
    
    // Step 2: Process each food fact
    await withThrowingTaskGroup(of: Void.self) { taskGroup in
      for row in foodRecordsToUpdate {
        if let foodItemRecordId = try? row.decode(column: "id", as: String.self) {
          taskGroup.addTask {
            application.logger.info("Generating AI accuracy report for food item \(foodItemRecordId)")
            _ = try await FoodItemAccuracyReport.generateReport(
              forFoodItemRecordWithID: FoodItemIdentifier(foodItemRecordId),
              db: application.db,
              openAIService: openAIService,
              imageStorage: application.imageStorage,
              openAIClient: application.openAI
            )
            application.logger.info("Updated accuracy report for food item: \(foodItemRecordId)")
          }
        }
      }
    }

    application.logger.info("Food fact accuracy job completed.")
  }
}
