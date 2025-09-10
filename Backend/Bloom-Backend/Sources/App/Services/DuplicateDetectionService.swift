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
    
    logger.info("Processing \(itemsToProcess.count) food items for duplicates")
    
    for item in itemsToProcess {
      do {
        try await processItem(item)
      } catch {
        logger.error("Failed to process item \(item.id ?? "unknown"): \(error)")
      }
    }
    
    logger.info("Completed duplicate detection batch processing")
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
  
  private func processItem(_ item: FoodItemRecord) async throws {
    guard let itemId = item.id else { return }
    
    // Find potential duplicates using existing similarity logic
    let duplicates = try await findSimilarItems(for: item)
    
    var highestScore: Double = 0.0
    
    for duplicate in duplicates {
      guard let duplicateId = duplicate.item.id,
            duplicate.similarityScore >= similarityThreshold else { continue }
      
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
    
    // Update item's duplicate score and last processed timestamp
    item.duplicateScore = highestScore > 0 ? highestScore : nil
    item.duplicateLastProcessed = Date()
    try await item.save(on: db)
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
    
    let nameSimilarity = calculateStringSimilarity(primary.name, duplicate.name)
    if nameSimilarity > 0.6 {
      matchTypes.append(.similarName)
    }
    
    if let primaryBrand = primary.brandName,
       let duplicateBrand = duplicate.brandName {
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
    let s1 = str1.lowercased()
    let s2 = str2.lowercased()
    
    if s1 == s2 { return 1.0 }
    
    let longer = s1.count > s2.count ? s1 : s2
    let shorter = s1.count > s2.count ? s2 : s1
    
    if longer.isEmpty { return 0.0 }
    
    let editDistance = levenshteinDistance(shorter, longer)
    return Double(longer.count - editDistance) / Double(longer.count)
  }
  
  private func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
    let s1Array = Array(s1)
    let s2Array = Array(s2)
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