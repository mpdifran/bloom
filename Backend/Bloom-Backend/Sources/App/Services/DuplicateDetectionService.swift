//
//  DuplicateDetectionService.swift
//  Bloom-Backend
//
//  Created by Assistant on 2025-09-09.
//

import AdminBloomModel
import BloomModel
import Fluent
import Foundation
import SQLKit
import Vapor

struct DuplicateDetectionService {
  let db: any Database
  let logger: Logger
  
  private let batchSize: Int
  private let similarityThreshold: Double
  private let processingIntervalHours: Double
  
  init(
    db: any Database,
    logger: Logger,
    batchSize: Int = 100,
    similarityThreshold: Double = 0.7,
    processingIntervalHours: Double = 24
  ) {
    self.db = db
    self.logger = logger
    self.batchSize = batchSize
    self.similarityThreshold = similarityThreshold
    self.processingIntervalHours = processingIntervalHours
  }
}

extension DuplicateDetectionService {
  func processNextBatch() async throws {
    logger.info("Starting duplicate detection batch processing")
    
    // Get items that need processing (prioritize never processed, then oldest processed)
    let cutoffDate = Date().addingTimeInterval(-processingIntervalHours * 3600)
    let itemsToProcess = try await getItemsNeedingProcessing(cutoffDate: cutoffDate)
    
    logger.info("Found \(itemsToProcess.count) food items to process for duplicates")
    
    var successCount = 0
    var failureCount = 0
    var itemsWithDuplicates = 0
    var itemsWithoutDuplicates = 0
    
    for (index, item) in itemsToProcess.enumerated() {
      do {
        logger.info("[\(index + 1)/\(itemsToProcess.count)] Processing item \(item.id ?? "unknown"): \(item.name)")
        let hadDuplicates = try await processItem(item)
        successCount += 1
        if hadDuplicates {
          itemsWithDuplicates += 1
        } else {
          itemsWithoutDuplicates += 1
        }
        logger.info("[\(index + 1)/\(itemsToProcess.count)] Successfully processed item \(item.id ?? "unknown")")
      } catch {
        failureCount += 1
        logger.error("[\(index + 1)/\(itemsToProcess.count)] Failed to process item \(item.id ?? "unknown"): \(error)")
      }
    }
    
    logger.info("""
      Duplicate detection batch completed:
      - Total items processed: \(itemsToProcess.count)
      - Successfully marked: \(successCount)
      - Failed to mark: \(failureCount)
      - Items with duplicates (score >= 0.7): \(itemsWithDuplicates)
      - Items without duplicates: \(itemsWithoutDuplicates)
      """)
  }
  
  private func getItemsNeedingProcessing(cutoffDate: Date) async throws -> [FoodItemRecord] {
    return try await FoodItemRecord.query(on: db)
      .group(.or) { group in
        // Never processed
        group.filter(\.$duplicateLastProcessed == nil)
        // Processed before cutoff date
        group.filter(\.$duplicateLastProcessed < cutoffDate)
      }
      .sort(\.$duplicateLastProcessed) // Null values first, then oldest
      .limit(batchSize)
      .all()
  }
  
  private func processItem(_ item: FoodItemRecord) async throws -> Bool {
    guard let itemId = item.id else {
      logger.warning("Skipping item with nil ID")
      return false
    }
    
    logger.debug("Finding similar items for \(itemId): \(item.name)")
    
    // Find potential duplicates using existing similarity logic
    let duplicates = try await findSimilarItems(for: item)
    
    logger.debug("Found \(duplicates.count) potential duplicates for \(itemId)")
    
    var highestScore: Double = 0.0
    var duplicatesAboveThreshold = 0
    
    for duplicate in duplicates {
      guard let duplicateId = duplicate.item.id,
            duplicate.similarityScore >= similarityThreshold else { continue }
      
      duplicatesAboveThreshold += 1
      
      // Check if we already have a relationship (in either direction) 
      let existingRelationship = try await FoodItemDuplicate.query(on: db)
        .group(.or) { group in
          group.group(.and) { and in
            and.filter(\.$foodItem.$id == itemId)
            and.filter(\.$duplicateFoodItem.$id == duplicateId)
          }
          group.group(.and) { and in
            and.filter(\.$foodItem.$id == duplicateId)
            and.filter(\.$duplicateFoodItem.$id == itemId)
          }
        }
        .first()
      
      if let existing = existingRelationship {
        // Update similarity score if it's higher
        if duplicate.similarityScore > existing.similarityScore {
          existing.similarityScore = duplicate.similarityScore
          existing.matchTypes = try encodeMatchTypes(duplicate.matchTypes)
          try await existing.save(on: db)
        }
      } else {
        // Create new relationship only if admin hasn't marked items as distinct
        let markedDistinct = try await FoodItemDuplicate.query(on: db)
          .group(.or) { group in
            group.group(.and) { and in
              and.filter(\.$foodItem.$id == itemId)
              and.filter(\.$duplicateFoodItem.$id == duplicateId)
              and.filter(\.$adminStatus == .markedDistinct)
            }
            group.group(.and) { and in
              and.filter(\.$foodItem.$id == duplicateId)
              and.filter(\.$duplicateFoodItem.$id == itemId)
              and.filter(\.$adminStatus == .markedDistinct)
            }
          }
          .first()
        
        if markedDistinct == nil {
          // Create new pending relationship
          let duplicateRelation = FoodItemDuplicate(
            foodItemID: itemId,
            duplicateFoodItemID: duplicateId,
            similarityScore: duplicate.similarityScore,
            matchTypes: try encodeMatchTypes(duplicate.matchTypes)
          )
          try await duplicateRelation.save(on: db)
          logger.info("Created duplicate relationship: \(itemId) <-> \(duplicateId) (score: \(duplicate.similarityScore))")
        }
      }
      
      highestScore = max(highestScore, duplicate.similarityScore)
    }
    
    logger.debug("Item \(itemId) has \(duplicatesAboveThreshold) duplicates above threshold (highest score: \(highestScore))")
    
    // Always update both fields - set score to 0.0 if no duplicates found
    item.duplicateScore = highestScore > 0 ? highestScore : 0.0
    item.duplicateLastProcessed = Date()
    
    // Explicitly save and verify
    do {
      logger.debug("Saving processing results for item \(itemId) - Score: \(item.duplicateScore ?? 0.0), Timestamp: \(item.duplicateLastProcessed?.description ?? "nil")")
      try await item.save(on: db)
      logger.info("Successfully saved item \(itemId) with score \(item.duplicateScore ?? 0.0) and timestamp \(item.duplicateLastProcessed?.description ?? "nil")")
    } catch {
      logger.error("Failed to save item \(itemId) after processing: \(error)")
      throw error
    }
    
    return highestScore >= similarityThreshold
  }
  
  private func findSimilarItems(for item: FoodItemRecord) async throws -> [(item: FoodItemRecord, similarityScore: Double, matchTypes: [MatchType])] {
    guard let sqlDatabase = db as? SQLDatabase else {
      throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
    }
    
    let results = try await sqlDatabase.raw("""
      SELECT *,
        GREATEST(
          similarity(name, \(bind: item.name)) * 1.5,
          similarity(brand_name, \(bind: item.brandName ?? "")) * 1.2,
          similarity(brand_name || ' ' || name || ' ' || flavour, 
                    \(bind: "\(item.brandName ?? "") \(item.name) \(item.flavour ?? "")")) * 2.0,
          CASE 
            WHEN barcode IS NOT NULL AND barcode = \(bind: item.barcode ?? "")
            THEN 1.0
            ELSE 0
          END
        ) AS similarity_score
      FROM food_item_records
      WHERE id != \(bind: item.id ?? "")
        AND (
          similarity(name, \(bind: item.name)) > 0.3
          OR similarity(brand_name, \(bind: item.brandName ?? "")) > 0.3
          OR (barcode IS NOT NULL AND barcode = \(bind: item.barcode ?? ""))
        )
      ORDER BY similarity_score DESC
      LIMIT 50
    """).all(decodingFluent: FoodItemRecord.self)
    
    var similarItems: [(item: FoodItemRecord, similarityScore: Double, matchTypes: [MatchType])] = []
    
    for duplicateRecord in results {
      let similarityScore = try await calculateSimilarity(between: item, and: duplicateRecord)
      
      if similarityScore >= 0.3 { // Lower threshold for broader analysis
        let matchTypes = determineMatchTypes(
          primary: item,
          duplicate: duplicateRecord,
          similarityScore: similarityScore
        )
        
        similarItems.append((
          item: duplicateRecord,
          similarityScore: similarityScore,
          matchTypes: matchTypes
        ))
      }
    }
    
    return similarItems
  }
  
  private func calculateSimilarity(between primary: FoodItemRecord, and duplicate: FoodItemRecord) async throws -> Double {
    guard let sqlDatabase = db as? SQLDatabase else {
      throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
    }
    
    let result = try await sqlDatabase.raw("""
      SELECT GREATEST(
        similarity(\(bind: primary.name), \(bind: duplicate.name)) * 1.5,
        similarity(\(bind: primary.brandName ?? ""), \(bind: duplicate.brandName ?? "")) * 1.2,
        similarity(
          \(bind: "\(primary.brandName ?? "") \(primary.name) \(primary.flavour ?? "")"),
          \(bind: "\(duplicate.brandName ?? "") \(duplicate.name) \(duplicate.flavour ?? "")")
        ) * 2.0,
        CASE 
          WHEN \(bind: primary.barcode ?? "") != '' 
            AND \(bind: primary.barcode ?? "") = \(bind: duplicate.barcode ?? "")
          THEN 1.0
          ELSE 0
        END
      ) AS similarity_score
    """).first()
    
    return try result?.decode(column: "similarity_score", as: Double.self) ?? 0.0
  }
  
  private func determineMatchTypes(
    primary: FoodItemRecord,
    duplicate: FoodItemRecord,
    similarityScore: Double
  ) -> [MatchType] {
    var matchTypes: [MatchType] = []
    
    if primary.barcode != nil && primary.barcode == duplicate.barcode {
      matchTypes.append(.exactBarcode)
    }
    
    // Safely calculate name similarity with nil checks
    let primaryName = primary.name.trimmingCharacters(in: .whitespacesAndNewlines)
    let duplicateName = duplicate.name.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if !primaryName.isEmpty && !duplicateName.isEmpty {
      let nameSimilarity = calculateStringSimilarity(primaryName, duplicateName)
      if nameSimilarity > 0.6 {
        matchTypes.append(.similarName)
      }
    }
    
    if let primaryBrand = primary.brandName?.trimmingCharacters(in: .whitespacesAndNewlines),
       let duplicateBrand = duplicate.brandName?.trimmingCharacters(in: .whitespacesAndNewlines),
       !primaryBrand.isEmpty && !duplicateBrand.isEmpty {
      let brandSimilarity = calculateStringSimilarity(primaryBrand, duplicateBrand)
      if brandSimilarity > 0.7 {
        matchTypes.append(.similarBrand)
      }
    }
    
    if let primaryCalories = primary.calories,
       let duplicateCalories = duplicate.calories,
       let primaryProtein = primary.protein,
       let duplicateProtein = duplicate.protein,
       let primaryCarbs = primary.carbohydrates,
       let duplicateCarbs = duplicate.carbohydrates,
       let primaryFat = primary.fat,
       let duplicateFat = duplicate.fat {
      
      let nutritionSimilarity = calculateNutritionSimilarity(
        calories1: primaryCalories, protein1: primaryProtein, carbs1: primaryCarbs, fat1: primaryFat,
        calories2: duplicateCalories, protein2: duplicateProtein, carbs2: duplicateCarbs, fat2: duplicateFat
      )
      
      if nutritionSimilarity > 0.85 {
        matchTypes.append(.similarNutrition)
      }
    }
    
    if matchTypes.isEmpty && similarityScore > 0.5 {
      matchTypes.append(.combined)
    }
    
    return matchTypes
  }
  
  private func calculateStringSimilarity(_ str1: String, _ str2: String) -> Double {
    // Limit string length to prevent memory issues
    let maxLength = 500
    let s1 = String(str1.lowercased().prefix(maxLength))
    let s2 = String(str2.lowercased().prefix(maxLength))
    
    if s1 == s2 { return 1.0 }
    
    let longer = s1.count > s2.count ? s1 : s2
    let shorter = s1.count > s2.count ? s2 : s1
    
    if longer.isEmpty { return 0.0 }
    
    // For very long strings, use a simpler comparison
    if longer.count > 200 {
      return simpleSimilarity(shorter, longer)
    }
    
    let editDistance = levenshteinDistance(shorter, longer)
    return Double(longer.count - editDistance) / Double(longer.count)
  }
  
  private func simpleSimilarity(_ str1: String, _ str2: String) -> Double {
    // Simple character-based similarity for long strings
    let set1 = Set(str1)
    let set2 = Set(str2)
    let intersection = set1.intersection(set2).count
    let union = set1.union(set2).count
    
    if union == 0 { return 0.0 }
    
    // Jaccard similarity combined with length ratio
    let jaccardSimilarity = Double(intersection) / Double(union)
    let lengthRatio = Double(min(str1.count, str2.count)) / Double(max(str1.count, str2.count))
    
    return (jaccardSimilarity * 0.7) + (lengthRatio * 0.3)
  }
  
  private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
    let s1Array = Array(s1)
    let s2Array = Array(s2)
    
    // Safety check: prevent excessive memory allocation
    guard s1Array.count <= 500 && s2Array.count <= 500 else {
      logger.warning("Strings too long for Levenshtein distance: \(s1Array.count) and \(s2Array.count) characters")
      // Return a high distance for very long strings
      return max(s1Array.count, s2Array.count)
    }
    
    // Early exit for empty strings
    if s1Array.isEmpty { return s2Array.count }
    if s2Array.isEmpty { return s1Array.count }
    
    var matrix = [[Int]](repeating: [Int](repeating: 0, count: s2Array.count + 1), count: s1Array.count + 1)
    
    for i in 0...s1Array.count {
      matrix[i][0] = i
    }
    
    for j in 0...s2Array.count {
      matrix[0][j] = j
    }
    
    for i in 1...s1Array.count {
      for j in 1...s2Array.count {
        let cost = s1Array[i - 1] == s2Array[j - 1] ? 0 : 1
        matrix[i][j] = min(
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost
        )
      }
    }
    
    return matrix[s1Array.count][s2Array.count]
  }
  
  private func calculateNutritionSimilarity(
    calories1: Double, protein1: Double, carbs1: Double, fat1: Double,
    calories2: Double, protein2: Double, carbs2: Double, fat2: Double
  ) -> Double {
    let caloriesDiff = abs(calories1 - calories2) / max(calories1, calories2, 1)
    let proteinDiff = abs(protein1 - protein2) / max(protein1, protein2, 1)
    let carbsDiff = abs(carbs1 - carbs2) / max(carbs1, carbs2, 1)
    let fatDiff = abs(fat1 - fat2) / max(fat1, fat2, 1)
    
    let avgDiff = (caloriesDiff + proteinDiff + carbsDiff + fatDiff) / 4
    return max(0, 1 - avgDiff)
  }
  
  private func encodeMatchTypes(_ matchTypes: [MatchType]) throws -> String {
    let encoder = JSONEncoder()
    let data = try encoder.encode(matchTypes.map { $0.rawValue })
    return String(data: data, encoding: .utf8) ?? "[]"
  }
}