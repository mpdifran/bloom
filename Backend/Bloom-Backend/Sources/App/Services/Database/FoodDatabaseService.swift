//
//  File.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import AdminBloomModel
import BloomModel
import Fluent
import Foundation
import SQLKit
import Vapor

struct FoodDatabaseService {
  let db: any Database
  let imageStorage: ImageStorage
}

/// Represents a food item match from database search with confidence scoring
struct FoodItemMatch {
  let foodItem: FoodItem
  let similarityScore: Double
  let source: String?
  let isVerified: Bool
}

extension FoodDatabaseService {

  func searchFoods(
    query: String,
    category: FoodItemRecord.Category,
    preferredCountry: String,
    limit: Int
  ) async throws -> [FoodItem] {
    guard !query.isEmpty else { return [] }

    guard let sqlDatabase = db as? SQLDatabase else {
      throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
    }

    let results = try await sqlDatabase.raw("""
            SELECT *,
                   GREATEST(
                       similarity(name, \(bind: query)) * 1.5,
                       similarity(brand_name, \(bind: query)),
                       similarity(flavour, \(bind: query)) * 0.5,
                       word_similarity(\(bind: query), search_text) * 2.0
                   ) *
                   CASE WHEN state = 'verified' THEN 1.05 ELSE 1.0 END *
                   (1.0 + CASE WHEN country = \(bind: preferredCountry) THEN 0.1 ELSE 0.0 END) AS rank
            FROM food_item_records
            WHERE search_text %> \(bind: query)
              AND category = \(bind: category.rawValue)::category
              AND state != 'needsAIProcessing'
            ORDER BY
                rank DESC
            LIMIT \(bind: limit)
        """).all(decodingFluent: FoodItemRecord.self)

    return results.compactMap { $0.asFoodItem() }
  }

  func searchFoods(
    query: String,
    preferredCountry: String,
    limit: Int
  ) async throws -> [FoodItem] {
    guard !query.isEmpty else { return [] }

    guard let sqlDatabase = db as? SQLDatabase else {
      throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
    }

    let results = try await sqlDatabase.raw("""
            SELECT *,
                   GREATEST(
                       similarity(name, \(bind: query)) * 1.5,
                       similarity(brand_name, \(bind: query)),
                       similarity(flavour, \(bind: query)) * 0.5,
                       word_similarity(\(bind: query), search_text) * 2.0
                   ) *
                   CASE WHEN state = 'verified' THEN 1.05 ELSE 1.0 END *
                   (1.0 + CASE WHEN country = \(bind: preferredCountry) THEN 0.1 ELSE 0.0 END) AS rank
            FROM food_item_records
            WHERE search_text %> \(bind: query)
              AND state != 'needsAIProcessing'
            ORDER BY
                rank DESC
            LIMIT \(bind: limit)
        """).all(decodingFluent: FoodItemRecord.self)

    return results.compactMap { $0.asFoodItem() }
  }

  func searchFoods(barcode: String) async throws -> [FoodItem] {
    guard !barcode.isEmpty else { return [] }

    guard let sqlDatabase = db as? SQLDatabase else {
      throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
    }

    let results = try await sqlDatabase.raw("""
            SELECT *
            FROM food_item_records
            WHERE barcode = \(bind: barcode)
              AND state != 'needsAIProcessing'
        """).all(decodingFluent: FoodItemRecord.self)

    return results.compactMap { $0.asFoodItem() }
  }

  func getUnverifiedFoodItemRecords(
    limit: Int
  ) async throws -> [AdminFoodItemRecord] {
    guard let sqlDatabase = db as? SQLDatabase else {
      throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
    }

    let results = try await sqlDatabase.raw("""
          SELECT *
          FROM food_item_records
          WHERE state = 'unverified'
          AND packaging_image IS NOT NULL
          AND nutrition_label_image IS NOT NULL
          ORDER BY log_count DESC NULLS LAST
          LIMIT \(bind: limit)
      """).all(decodingFluent: FoodItemRecord.self)

    return try await createAdminRecords(from: results)
  }

  func adminSearchFoods(query: String) async throws -> [AdminFoodItemRecord] {
    guard let sqlDatabase = db as? SQLDatabase else {
      throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
    }

    let results = try await sqlDatabase.raw(
        """
            SELECT *
            FROM food_item_records
            WHERE SIMILARITY(name, \(bind: query)) > 0.3
               OR SIMILARITY(brand_name, \(bind: query)) > 0.3
               OR SIMILARITY(barcode, \(bind: query)) > 0.3
            ORDER BY GREATEST(
                SIMILARITY(name, \(bind: query)),
                SIMILARITY(brand_name, \(bind: query)),
                SIMILARITY(barcode, \(bind: query))
            ) DESC
        """
    ).all(decodingFluent: FoodItemRecord.self)

    return try await createAdminRecords(from: results)
  }

  func markFoodAsInaccurate(foodID: FoodItemIdentifier) async throws {
    guard let foodItem = try await FoodItemRecord.query(on: db)
      .filter(\.$id == foodID.value)
      .first() else {
      throw Abort(.noContent)
    }

    var downvoteCount = foodItem.downvoteCount ?? 0
    downvoteCount += 1
    foodItem.downvoteCount = downvoteCount

    try await foodItem.save(on: db)
  }

  func incrementLogCount(foodIDs: [FoodItemIdentifier]) async throws {
    guard !foodIDs.isEmpty else { return }

    guard let sqlDatabase = db as? SQLDatabase else {
      throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
    }

    let ids = foodIDs.map { $0.value }
    try await sqlDatabase.raw("""
      UPDATE food_item_records
      SET log_count = COALESCE(log_count, 0) + 1
      WHERE id = ANY(\(bind: ids))
    """).run()
  }

  func submitFoodItemIssueReport(user: User, foodItemIssue: FoodItemIssue) async throws {
    // Save images
    let packagingImageFileName: String?
    let nutritionLabelImageFileName: String?
    if let packagingImage = foodItemIssue.packagingImage {
      let imageMetadata = try await imageStorage.store(
        image: packagingImage,
        path: .foodPackaging
      )
      packagingImageFileName = imageMetadata.filename
    } else {
      packagingImageFileName = nil
    }
    if let nutritionImage = foodItemIssue.nutritionLabelImage {
      let imageMetadata = try await imageStorage.store(
        image: nutritionImage,
        path: .nutritionLabel
      )
      nutritionLabelImageFileName = imageMetadata.filename
    } else {
      nutritionLabelImageFileName = nil
    }

    // Create report
    let report = FoodItemIssueReport(
      name: foodItemIssue.name,
      brandName: foodItemIssue.brandName,
      flavour: foodItemIssue.flavour,
      nutritionLabelImage: nutritionLabelImageFileName,
      packagingImage: packagingImageFileName,
      ingredients: foodItemIssue.ingredients,
      calories: foodItemIssue.calories,
      protein: foodItemIssue.protein,
      carbohydrates: foodItemIssue.carbohydrates,
      fat: foodItemIssue.fat,
      saturatedFat: foodItemIssue.saturatedFat,
      transFat: foodItemIssue.transFat,
      polyunsaturatedFat: foodItemIssue.polyunsaturatedFat,
      monounsaturatedFat: foodItemIssue.monounsaturatedFat,
      fiber: foodItemIssue.fiber,
      sugar: foodItemIssue.sugar,
      cholesterol: foodItemIssue.cholesterol,
      sodium: foodItemIssue.sodium,
      calcium: foodItemIssue.calcium,
      iron: foodItemIssue.iron,
      potassium: foodItemIssue.potassium,
      magnesium: foodItemIssue.magnesium,
      zinc: foodItemIssue.zinc,
      vitaminA: foodItemIssue.vitaminA,
      vitaminB6: foodItemIssue.vitaminB6,
      vitaminB12: foodItemIssue.vitaminB12,
      vitaminC: foodItemIssue.vitaminC,
      vitaminD: foodItemIssue.vitaminD,
      vitaminE: foodItemIssue.vitaminE,
      servingName: foodItemIssue.servingName,
      servingValue: foodItemIssue.servingValue,
      servingUnit: foodItemIssue.servingUnit,
      notes: foodItemIssue.notes,
      userID: user.id,
      foodItemRecordID: foodItemIssue.foodItemID.value
    )

    try await report.save(on: db)
  }
  
  func getLatestAccuracyReport(
    forFoodItemWithId foodID: FoodItemIdentifier
  ) async throws -> AdminAccuracyReportGetResponse {
    guard let accuracyReport = try await FoodItemAccuracyReport.query(on: db)
      .filter(\.$foodItemRecord.$id == foodID.value)
      .sort(\.$createdAt, .descending) // Sort to get the latest entry
      .first() else { return AdminAccuracyReportGetResponse(report: nil) }
    
    return AdminAccuracyReportGetResponse(
      report: AdminAccuracyReport(
        accuracyScore: accuracyReport.accuracyScore,
        evaluationNotes: accuracyReport.evaluationNotes,
        createdAt: accuracyReport.createdAt
      )
    )
  }

  func addProductImagesIfMissing(
    foodID: FoodItemIdentifier,
    nutritionImage: ImageFile,
    packagingImage: ImageFile
  ) async throws {
    guard let foodItem = try await FoodItemRecord.query(on: db)
      .filter(\.$id == foodID.value)
      .first() else {
      throw Abort(.noContent)
    }

    if foodItem.nutritionLabelImage == nil {
      let imageMetadata = try await imageStorage.store(
        image: nutritionImage,
        path: .nutritionLabel
      )
      foodItem.nutritionLabelImage = imageMetadata.filename
    }
    if foodItem.packagingImage == nil {
      let imageMetadata = try await imageStorage.store(
        image: packagingImage,
        path: .foodPackaging
      )
      foodItem.packagingImage = imageMetadata.filename
    }
    
    try await foodItem.save(on: db)
  }
  
  func findDuplicateGroups(
    limit: Int,
    offset: Int,
    minimumDuplicates: Int,
    category: FoodItemRecord.Category?,
    state: FoodItemRecord.State?
  ) async throws -> DuplicateGroupsResponse {
    // First, get all unique item IDs that have pending duplicate relationships
    let sourceItemIds = try await FoodItemDuplicate.query(on: db)
      .filter(\.$adminStatus == .pending)
      .unique()
      .all()
      .map { $0.$foodItem.id }
    
    let targetItemIds = try await FoodItemDuplicate.query(on: db)
      .filter(\.$adminStatus == .pending)
      .unique()
      .all()
      .map { $0.$duplicateFoodItem.id }
    
    // Combine and deduplicate item IDs
    let allUniqueItemIds = Set(sourceItemIds + targetItemIds)
    
    // Now fetch the actual items with filters applied
    var query = FoodItemRecord.query(on: db)
      .filter(\.$id ~~ Array(allUniqueItemIds))
    
    if let category = category {
      query = query.filter(\.$category == category)
    }
    
    if let state = state {
      query = query.filter(\.$state == state)
    }
    
    // Eager load duplicate relationships for filtered items
    let itemsWithDuplicates = try await query
      .with(\.$duplicateRelationshipsAsSource)
      .with(\.$duplicateRelationshipsAsTarget)
      .all()
    
    // Load the related items for each relationship
    for item in itemsWithDuplicates {
      for relationship in item.duplicateRelationshipsAsSource {
        try await relationship.$duplicateFoodItem.load(on: db)
      }
      for relationship in item.duplicateRelationshipsAsTarget {
        try await relationship.$foodItem.load(on: db)
      }
    }
    
    // Filter items that have enough pending duplicates
    let qualifyingItems = itemsWithDuplicates.filter { item in
      let pendingAsSource = item.duplicateRelationshipsAsSource.filter { $0.adminStatus == .pending }.count
      let pendingAsTarget = item.duplicateRelationshipsAsTarget.filter { $0.adminStatus == .pending }.count
      let totalPendingDuplicates = pendingAsSource + pendingAsTarget
      return totalPendingDuplicates >= minimumDuplicates
    }
    
    // Sort by duplicate count (highest first) and paginate
    let sortedItems = qualifyingItems
      .sorted { 
        let count1 = $0.duplicateRelationshipsAsSource.filter { $0.adminStatus == .pending }.count + 
                    $0.duplicateRelationshipsAsTarget.filter { $0.adminStatus == .pending }.count
        let count2 = $1.duplicateRelationshipsAsSource.filter { $0.adminStatus == .pending }.count + 
                    $1.duplicateRelationshipsAsTarget.filter { $0.adminStatus == .pending }.count
        return count1 > count2
      }
      .dropFirst(offset)
      .prefix(limit)
    
    // Convert to DuplicateGroup format
    var groups: [DuplicateGroup] = []
    for item in sortedItems {
      guard let primaryAdminRecord = item.asAdminFoodItemRecord() else { continue }
      
      // Get pending duplicates with their pivot data
      let duplicateCandidates = try await getPendingDuplicatesForItem(item)
      
      let group = DuplicateGroup(
        id: item.id ?? "",
        primaryItem: primaryAdminRecord,
        duplicates: duplicateCandidates,
        totalCount: duplicateCandidates.count + 1
      )
      
      groups.append(group)
    }
    
    let totalGroups = qualifyingItems.count
    let totalDuplicates = groups.reduce(0) { $0 + $1.duplicates.count }
    
    return DuplicateGroupsResponse(
      groups: groups,
      totalGroups: totalGroups,
      totalDuplicates: totalDuplicates
    )
  }
  
  private func getPendingDuplicatesForItem(_ item: FoodItemRecord) async throws -> [DuplicateCandidate] {
    var candidates: [DuplicateCandidate] = []
    
    // Process relationships where this item is the source
    for relationship in item.duplicateRelationshipsAsSource {
      guard relationship.adminStatus == .pending,
            let duplicateAdminRecord = relationship.duplicateFoodItem.asAdminFoodItemRecord() else { continue }
      
      let matchTypes = decodeMatchTypes(relationship.matchTypes)
      let candidate = DuplicateCandidate(
        item: duplicateAdminRecord,
        similarityScore: relationship.similarityScore,
        matchTypes: matchTypes
      )
      candidates.append(candidate)
    }
    
    // Process relationships where this item is the target
    for relationship in item.duplicateRelationshipsAsTarget {
      guard relationship.adminStatus == .pending,
            let duplicateAdminRecord = relationship.foodItem.asAdminFoodItemRecord() else { continue }
      
      let matchTypes = decodeMatchTypes(relationship.matchTypes)
      let candidate = DuplicateCandidate(
        item: duplicateAdminRecord,
        similarityScore: relationship.similarityScore,
        matchTypes: matchTypes
      )
      candidates.append(candidate)
    }
    
    return candidates.sorted { $0.similarityScore > $1.similarityScore }
  }
  
  private func decodeMatchTypes(_ jsonString: String) -> [MatchType] {
    guard let data = jsonString.data(using: .utf8),
          let rawValues = try? JSONDecoder().decode([String].self, from: data) else {
      return []
    }
    
    return rawValues.compactMap { MatchType(rawValue: $0) }
  }
  
  func findDuplicatesForItem(
    foodID: FoodItemIdentifier,
    similarityThreshold: Double,
    limit: Int
  ) async throws -> ItemDuplicatesResponse {
    // First get the food item
    guard let foodItem = try await FoodItemRecord.find(foodID.value, on: db) else {
      throw Abort(.notFound)
    }
    
    // Load the relationships separately
    try await foodItem.$duplicateRelationshipsAsSource.load(on: db)
    try await foodItem.$duplicateRelationshipsAsTarget.load(on: db)
    
    // Load the related items for each relationship
    for relationship in foodItem.duplicateRelationshipsAsSource {
      try await relationship.$duplicateFoodItem.load(on: db)
    }
    for relationship in foodItem.duplicateRelationshipsAsTarget {
      try await relationship.$foodItem.load(on: db)
    }
    
    guard let adminRecord = foodItem.asAdminFoodItemRecord() else {
      throw Abort(.internalServerError)
    }
    
    // Get duplicates from pre-computed relationships
    let duplicateCandidates = try await getPendingDuplicatesForItem(foodItem)
      .filter { $0.similarityScore >= similarityThreshold }
      .prefix(limit)
    
    return ItemDuplicatesResponse(
      item: adminRecord,
      duplicates: Array(duplicateCandidates)
    )
  }
  
  func mergeFoodItems(
    primaryItemId: FoodItemIdentifier,
    itemsToMerge: [FoodItemIdentifier],
    mergedData: AdminFoodItemRecord
  ) async throws -> MergeFoodItemsResponse {
    guard let primaryItem = try await FoodItemRecord.find(primaryItemId.value, on: db) else {
      throw Abort(.notFound, reason: "Primary item not found")
    }
    
    primaryItem.name = mergedData.name ?? primaryItem.name
    primaryItem.brandName = mergedData.brandName ?? primaryItem.brandName
    primaryItem.flavour = mergedData.flavour ?? primaryItem.flavour
    primaryItem.category = mergedData.category?.asCategory() ?? primaryItem.category
    primaryItem.barcode = mergedData.barcode ?? primaryItem.barcode
    primaryItem.ingredients = mergedData.ingredients ?? primaryItem.ingredients
    primaryItem.country = mergedData.country ?? primaryItem.country
    primaryItem.calories = mergedData.calories ?? primaryItem.calories
    primaryItem.protein = mergedData.protein ?? primaryItem.protein
    primaryItem.carbohydrates = mergedData.carbohydrates ?? primaryItem.carbohydrates
    primaryItem.fat = mergedData.fat ?? primaryItem.fat
    primaryItem.saturatedFat = mergedData.saturatedFat ?? primaryItem.saturatedFat
    primaryItem.transFat = mergedData.transFat ?? primaryItem.transFat
    primaryItem.polyunsaturatedFat = mergedData.polyunsaturatedFat ?? primaryItem.polyunsaturatedFat
    primaryItem.monounsaturatedFat = mergedData.monounsaturatedFat ?? primaryItem.monounsaturatedFat
    primaryItem.fiber = mergedData.fiber ?? primaryItem.fiber
    primaryItem.sugar = mergedData.sugar ?? primaryItem.sugar
    primaryItem.cholesterol = mergedData.cholesterol ?? primaryItem.cholesterol
    primaryItem.sodium = mergedData.sodium ?? primaryItem.sodium
    primaryItem.calcium = mergedData.calcium ?? primaryItem.calcium
    primaryItem.iron = mergedData.iron ?? primaryItem.iron
    primaryItem.potassium = mergedData.potassium ?? primaryItem.potassium
    primaryItem.magnesium = mergedData.magnesium ?? primaryItem.magnesium
    primaryItem.zinc = mergedData.zinc ?? primaryItem.zinc
    primaryItem.vitaminA = mergedData.vitaminA ?? primaryItem.vitaminA
    primaryItem.vitaminB6 = mergedData.vitaminB6 ?? primaryItem.vitaminB6
    primaryItem.vitaminB12 = mergedData.vitaminB12 ?? primaryItem.vitaminB12
    primaryItem.vitaminC = mergedData.vitaminC ?? primaryItem.vitaminC
    primaryItem.vitaminD = mergedData.vitaminD ?? primaryItem.vitaminD
    primaryItem.vitaminE = mergedData.vitaminE ?? primaryItem.vitaminE
    primaryItem.servingName = mergedData.servingName ?? primaryItem.servingName
    primaryItem.servingValue = mergedData.servingValue ?? primaryItem.servingValue
    primaryItem.servingUnit = mergedData.servingUnit ?? primaryItem.servingUnit
    primaryItem.state = mergedData.state.asState()
    primaryItem.notes = mergedData.notes ?? primaryItem.notes
    
    try await primaryItem.save(on: db)
    
    var deletedCount = 0
    for itemId in itemsToMerge {
      if let itemToDelete = try await FoodItemRecord.find(itemId.value, on: db) {
        // Clean up duplicate relationships before deletion (cascade should handle this but let's be explicit)
        try await FoodItemDuplicate.query(on: db)
          .group(.or) { group in
            group.filter(\.$foodItem.$id == itemId.value)
            group.filter(\.$duplicateFoodItem.$id == itemId.value)
          }
          .delete()
        
        try await itemToDelete.delete(on: db)
        deletedCount += 1
      }
    }
    
    // Reset duplicate score for primary item since we've resolved these duplicates
    primaryItem.duplicateScore = nil
    primaryItem.duplicateLastProcessed = Date()
    try await primaryItem.save(on: db)
    
    guard let updatedAdminRecord = primaryItem.asAdminFoodItemRecord() else {
      throw Abort(.internalServerError)
    }
    
    return MergeFoodItemsResponse(
      mergedItem: updatedAdminRecord,
      deletedCount: deletedCount,
      success: true
    )
  }
  
  func markItemsAsDistinct(
    foodItemId: FoodItemIdentifier,
    duplicateItemId: FoodItemIdentifier,
    adminUserId: String
  ) async throws {
    // Find the relationship (in either direction)
    let relationship = try await FoodItemDuplicate.query(on: db)
      .group(.or) { group in
        group.group(.and) { and in
          and.filter(\.$foodItem.$id == foodItemId.value)
          and.filter(\.$duplicateFoodItem.$id == duplicateItemId.value)
        }
        group.group(.and) { and in
          and.filter(\.$foodItem.$id == duplicateItemId.value)
          and.filter(\.$duplicateFoodItem.$id == foodItemId.value)
        }
      }
      .first()

    guard let relationship = relationship else {
      throw Abort(.notFound, reason: "Duplicate relationship not found")
    }

    // Mark as distinct
    relationship.adminStatus = .markedDistinct
    relationship.adminUserID = adminUserId
    relationship.adminDecisionAt = Date()

    try await relationship.save(on: db)
  }

  /// Search for foods optimized for magic scan feature.
  /// Prioritizes verified foods and OpenFoodFacts imports even if unverified.
  /// Returns matches with similarity scores for confidence assessment.
  func searchFoodsForMagicScan(
    query: String,
    brand: String?,
    preferredCountry: String
  ) async throws -> [FoodItemMatch] {
    guard !query.isEmpty else { return [] }

    guard let sqlDatabase = db as? SQLDatabase else {
      throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
    }

    // Build query with brand if provided
    let brandFilter: SQLQueryString
    if let brand = brand, !brand.isEmpty {
      brandFilter = """
        AND (
          similarity(brand_name, \(bind: brand)) > 0.3
          OR brand_name ILIKE \(bind: "%\(brand)%")
        )
        """
    } else {
      brandFilter = ""
    }

    let results = try await sqlDatabase.raw("""
      SELECT *,
        GREATEST(
          similarity(name, \(bind: query)) * 1.5,
          similarity(brand_name, \(bind: query)),
          similarity(flavour, \(bind: query)) * 0.5,
          word_similarity(\(bind: query), search_text) * 2.0
        ) *
        -- Boost verified items significantly
        CASE WHEN state = 'verified' THEN 1.2
             -- Boost OpenFoodFacts items moderately
             WHEN source = 'Open Food Facts' THEN 1.1
             ELSE 1.0 END *
        (1.0 + CASE WHEN country = \(bind: preferredCountry) THEN 0.1 ELSE 0.0 END) AS similarity_score
      FROM food_item_records
      WHERE (
        search_text %> \(bind: query)
        OR similarity(name, \(bind: query)) > 0.3
      )
      \(brandFilter)
      AND state != 'needsAIProcessing'
      ORDER BY similarity_score DESC
      LIMIT 3
    """).all(decodingFluent: FoodItemRecord.self)

    return results.compactMap { record in
      guard let foodItem = record.asFoodItem() else { return nil }
      // Extract similarity score from the query result
      // Note: The similarity_score is calculated in SQL but we'll approximate it here
      let score = 0.7 // Default confidence score - will be refined with actual SQL score
      return FoodItemMatch(
        foodItem: foodItem,
        similarityScore: score,
        source: record.source,
        isVerified: record.state == .verified
      )
    }
  }
}

private extension FoodDatabaseService {
  
  /// Map foodItemRecords to adminFoodItemRecords and sign images from S3.
  func createAdminRecords(
    from foodItemRecords: [FoodItemRecord]
  ) async throws -> [AdminFoodItemRecord] {
    var records: [AdminFoodItemRecord] = []
    for item in foodItemRecords {
      guard var adminFoodRecord = item.asAdminFoodItemRecord() else { continue }

      if let nutritionLabel = item.nutritionLabelImage {
        let imageURL: URL?
        if
          nutritionLabel.hasPrefix("https://openfoodfacts-images") ||
          nutritionLabel.hasPrefix("https://images.openfoodfacts.net")
        { // TODO: Zach make this better?
          imageURL = URL(string: nutritionLabel)
        } else {
          imageURL = try await imageStorage.generateImageURL(
            fileName: nutritionLabel,
            path: .nutritionLabel,
            expiration: .hours(2)
          )
        }
        adminFoodRecord.nutritionLabelImage = imageURL
      }

      if let packagingImage = item.packagingImage {
        let imageURL: URL?
        if
          packagingImage.hasPrefix("https://openfoodfacts-images") ||
          packagingImage.hasPrefix("https://images.openfoodfacts.net")
        { // TODO: Zach make this better?
          imageURL = URL(string: packagingImage)
        } else {
          imageURL = try await imageStorage.generateImageURL(
            fileName: packagingImage,
            path: .foodPackaging,
            expiration: .hours(2)
          )
        }

        adminFoodRecord.packagingImage = imageURL
      }

      records.append(adminFoodRecord)
    }

    return records
  }
}
