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
                       similarity(brand_name || ' ' || name || ' ' || flavour, \(bind: query)) * 2.0
                   ) *
                   CASE WHEN state = 'verified' THEN 1.05 ELSE 1.0 END * 
                   (1.0 + similarity(country, \(bind: preferredCountry)) * 0.1) AS rank
            FROM food_item_records
            WHERE (similarity(name, \(bind: query)) > 0.1
               OR similarity(brand_name, \(bind: query)) > 0.1
               OR similarity(flavour, \(bind: query)) > 0.1
               OR similarity(brand_name || ' ' || name || ' ' || flavour, \(bind: query)) > 0.1)
              AND category = \(bind: category.rawValue)::category
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
    guard let sqlDatabase = db as? SQLDatabase else {
      throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
    }
    
    var categoryFilter = ""
    if let category = category {
      categoryFilter = "AND f1.category = '\(category.rawValue)'::category"
    }
    
    var stateFilter = ""
    if let state = state {
      stateFilter = "AND f1.state = '\(state.rawValue)'"
    }
    
    let groupsQuery = """
      WITH duplicate_pairs AS (
        SELECT DISTINCT
          f1.id AS primary_id,
          f2.id AS duplicate_id,
          GREATEST(
            similarity(f1.name, f2.name) * 1.5,
            similarity(f1.brand_name, f2.brand_name),
            similarity(f1.brand_name || ' ' || f1.name || ' ' || f1.flavour, 
                      f2.brand_name || ' ' || f2.name || ' ' || f2.flavour) * 2.0,
            CASE 
              WHEN f1.barcode IS NOT NULL AND f1.barcode = f2.barcode THEN 1.0
              ELSE 0
            END
          ) AS similarity_score
        FROM food_item_records f1
        JOIN food_item_records f2 ON f1.id < f2.id
        WHERE (
          similarity(f1.name, f2.name) > 0.4
          OR similarity(f1.brand_name, f2.brand_name) > 0.5
          OR (f1.barcode IS NOT NULL AND f1.barcode = f2.barcode)
        )
        \(categoryFilter)
        \(stateFilter)
      ),
      grouped_duplicates AS (
        SELECT 
          primary_id,
          ARRAY_AGG(duplicate_id) AS duplicate_ids,
          COUNT(*) + 1 AS total_count
        FROM duplicate_pairs
        GROUP BY primary_id
        HAVING COUNT(*) >= \(minimumDuplicates - 1)
        ORDER BY COUNT(*) DESC
        LIMIT \(limit)
        OFFSET \(offset)
      )
      SELECT 
        gd.primary_id,
        gd.duplicate_ids,
        gd.total_count,
        f.*
      FROM grouped_duplicates gd
      JOIN food_item_records f ON f.id = gd.primary_id
    """
    
    let results = try await sqlDatabase.raw(SQLQueryString(groupsQuery))
      .all()
    
    var groups: [DuplicateGroup] = []
    var totalDuplicates = 0
    
    for row in results {
      guard 
        let primaryId = try? row.decode(column: "primary_id", as: String.self),
        let duplicateIds = try? row.decode(column: "duplicate_ids", as: [String].self),
        let totalCount = try? row.decode(column: "total_count", as: Int.self)
      else { continue }
      
      let primaryRecord = try row.decode(fluentModel: FoodItemRecord.self)
      guard let primaryAdminRecord = primaryRecord.asAdminFoodItemRecord() else { continue }
      
      var duplicateCandidates: [DuplicateCandidate] = []
      for duplicateId in duplicateIds {
        if let duplicateRecord = try await FoodItemRecord.find(duplicateId, on: db),
           let adminRecord = duplicateRecord.asAdminFoodItemRecord() {
          
          let similarityScore = try await calculateSimilarity(
            between: primaryRecord,
            and: duplicateRecord
          )
          
          let matchTypes = determineMatchTypes(
            primary: primaryRecord,
            duplicate: duplicateRecord,
            similarityScore: similarityScore
          )
          
          duplicateCandidates.append(
            DuplicateCandidate(
              item: adminRecord,
              similarityScore: similarityScore,
              matchTypes: matchTypes
            )
          )
        }
      }
      
      let group = DuplicateGroup(
        id: primaryId,
        primaryItem: primaryAdminRecord,
        duplicates: duplicateCandidates,
        totalCount: totalCount
      )
      
      groups.append(group)
      totalDuplicates += duplicateCandidates.count
    }
    
    let totalGroupsQuery = """
      WITH duplicate_pairs AS (
        SELECT DISTINCT
          f1.id AS primary_id,
          f2.id AS duplicate_id
        FROM food_item_records f1
        JOIN food_item_records f2 ON f1.id < f2.id
        WHERE (
          similarity(f1.name, f2.name) > 0.4
          OR similarity(f1.brand_name, f2.brand_name) > 0.5
          OR (f1.barcode IS NOT NULL AND f1.barcode = f2.barcode)
        )
        \(categoryFilter)
        \(stateFilter)
      )
      SELECT COUNT(DISTINCT primary_id) AS total_groups
      FROM (
        SELECT primary_id
        FROM duplicate_pairs
        GROUP BY primary_id
        HAVING COUNT(*) >= \(minimumDuplicates - 1)
      ) AS grouped
    """
    
    let totalResult = try await sqlDatabase.raw(SQLQueryString(totalGroupsQuery))
      .first()
    
    let totalGroups = try totalResult?.decode(column: "total_groups", as: Int.self) ?? 0
    
    return DuplicateGroupsResponse(
      groups: groups,
      totalGroups: totalGroups,
      totalDuplicates: totalDuplicates
    )
  }
  
  func findDuplicatesForItem(
    foodID: FoodItemIdentifier,
    similarityThreshold: Double,
    limit: Int
  ) async throws -> ItemDuplicatesResponse {
    guard let foodItem = try await FoodItemRecord.find(foodID.value, on: db) else {
      throw Abort(.notFound)
    }
    
    guard let adminRecord = foodItem.asAdminFoodItemRecord() else {
      throw Abort(.internalServerError)
    }
    
    guard let sqlDatabase = db as? SQLDatabase else {
      throw Abort(.internalServerError, reason: "Database is not SQLDatabase compatible.")
    }
    
    let results = try await sqlDatabase.raw("""
      SELECT *,
        GREATEST(
          similarity(name, \(bind: foodItem.name)) * 1.5,
          similarity(brand_name, \(bind: foodItem.brandName ?? "")) * 1.2,
          similarity(brand_name || ' ' || name || ' ' || flavour, 
                    \(bind: "\(foodItem.brandName ?? "") \(foodItem.name) \(foodItem.flavour ?? "")")) * 2.0,
          CASE 
            WHEN barcode IS NOT NULL AND barcode = \(bind: foodItem.barcode ?? "")
            THEN 1.0
            ELSE 0
          END
        ) AS similarity_score
      FROM food_item_records
      WHERE id != \(bind: foodID.value)
        AND (
          similarity(name, \(bind: foodItem.name)) > \(bind: similarityThreshold)
          OR similarity(brand_name, \(bind: foodItem.brandName ?? "")) > \(bind: similarityThreshold)
          OR (barcode IS NOT NULL AND barcode = \(bind: foodItem.barcode ?? ""))
        )
      ORDER BY similarity_score DESC
      LIMIT \(bind: limit)
    """)
      .all(decodingFluent: FoodItemRecord.self)
    
    var duplicates: [DuplicateCandidate] = []
    
    for duplicateRecord in results {
      guard let duplicateAdminRecord = duplicateRecord.asAdminFoodItemRecord() else { continue }
      
      let similarityScore = try await calculateSimilarity(
        between: foodItem,
        and: duplicateRecord
      )
      
      let matchTypes = determineMatchTypes(
        primary: foodItem,
        duplicate: duplicateRecord,
        similarityScore: similarityScore
      )
      
      duplicates.append(
        DuplicateCandidate(
          item: duplicateAdminRecord,
          similarityScore: similarityScore,
          matchTypes: matchTypes
        )
      )
    }
    
    return ItemDuplicatesResponse(
      item: adminRecord,
      duplicates: duplicates
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
        try await itemToDelete.delete(on: db)
        deletedCount += 1
      }
    }
    
    guard let updatedAdminRecord = primaryItem.asAdminFoodItemRecord() else {
      throw Abort(.internalServerError)
    }
    
    return MergeFoodItemsResponse(
      mergedItem: updatedAdminRecord,
      deletedCount: deletedCount,
      success: true
    )
  }
}

private extension FoodDatabaseService {
  func calculateSimilarity(
    between primary: FoodItemRecord,
    and duplicate: FoodItemRecord
  ) async throws -> Double {
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
  
  func determineMatchTypes(
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
        calories1: primaryCalories,
        protein1: primaryProtein,
        carbs1: primaryCarbs,
        fat1: primaryFat,
        calories2: duplicateCalories,
        protein2: duplicateProtein,
        carbs2: duplicateCarbs,
        fat2: duplicateFat
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
  
  func calculateStringSimilarity(_ str1: String, _ str2: String) -> Double {
    let s1 = str1.lowercased()
    let s2 = str2.lowercased()
    
    if s1 == s2 { return 1.0 }
    
    let longer = s1.count > s2.count ? s1 : s2
    let shorter = s1.count > s2.count ? s2 : s1
    
    if longer.isEmpty { return 0.0 }
    
    let editDistance = levenshteinDistance(shorter, longer)
    return Double(longer.count - editDistance) / Double(longer.count)
  }
  
  func levenshteinDistance(_ s1: String, _ s2: String) -> Int {
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
  
  func calculateNutritionSimilarity(
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
