//
//  AdminFoodController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import AdminBloomModel
import BloomModel
import Fluent
import Foundation
import Vapor

struct AdminFoodController { }

extension AdminFoodController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "admin") {
      $0.auth(using: AdminUserToken.self) {
        $0.group("food") {
          $0.post("usda-ingest", use: ingestUSDA)
          $0.get("unverified", use: getUnverifiedFoods)
          $0.post("create", use: createFood)
          $0.patch("update", use: updateFood)
          $0.delete(":id", use: deleteFood)
          $0.get("search", use: searchFood)
          $0.get("accuracy-report", use: getAccuracyReport)
          $0.post("regenerate-accuracy-report", use: evaluateAccuracy)
          
          $0.group("duplicates") {
            $0.get("groups", use: getDuplicateGroups)
            $0.get(":id", use: getDuplicatesForItem)
            $0.post("merge", use: mergeFoodItems)
            $0.post("mark-distinct", use: markItemsAsDistinct)
            $0.post("run-detection", use: runDuplicateDetection)
          }

          $0.group("issue-reports") {
            $0.get(use: getIssueReports)
            $0.post("apply", use: applyIssueReport)
            $0.delete(":id", use: deleteIssueReport)
          }
        }
      }
    }
  }
}

private extension AdminFoodController {

  @Sendable
  func ingestUSDA(_ request: Request) async throws -> USDAImportFoodResponse {
    let requestBody = try request.content.decode(USDAImportFoodRequest.self)

    let category: FoodItemRecord.Category
    switch requestBody.kind {
    case .foundation:
      category = .generic
    }

    var count = 0
    for foodItem in requestBody.foods {
      guard
        let foodItemRecord = try await foodItem.asFoodItemRecord(
          request: request,
          category: category
        )
      else { continue }

      try await foodItemRecord.createOrUpdate(on: request.db)
      count += 1
    }

    return USDAImportFoodResponse(addedFoodItemsCount: count)
  }

  @Sendable
  func getUnverifiedFoods(_ request: Request) async throws -> UnverifiedFoodItemsResponse {
    let query = try request.query.decode(UnverifiedFoodGetRequest.self)
    let limit = query.limit ?? 500 // Default to 100 if not provided.

    let foodItemRecords = try await request.foodDatabaseService.getUnverifiedFoodItemRecords(limit: limit)

    return UnverifiedFoodItemsResponse(foodItemRecords: foodItemRecords)
  }

  @Sendable
  func createFood(_ request: Request) async throws -> AdminCreateFoodItemResponse {
    let requestBody = try request.content.decode(AdminCreateFoodItemRequest.self)
    let createRecord = requestBody.foodItemRecord
    let createNutritionLabelImage = requestBody.nutritionLabelImage
    let createPackagingImage = requestBody.packagingImage

    try Self.validateCreateFoodRecord(createRecord)
    
    let newRecord = FoodItemRecord(
      id: UUID().uuidString,
      name: createRecord.name ?? "",
      state: createRecord.state.asState(),
      brandName: createRecord.brandName,
      flavour: createRecord.flavour,
      category: createRecord.category?.asCategory() ?? .generic,
      barcode: createRecord.barcode,
      nutritionLabelImage: nil, // Will be set below if image is provided
      packagingImage: nil, // Will be set below if image is provided
      ingredients: createRecord.ingredients,
      country: createRecord.country ?? "canada",
      calories: createRecord.calories,
      protein: createRecord.protein,
      carbohydrates: createRecord.carbohydrates,
      fat: createRecord.fat,
      saturatedFat: createRecord.saturatedFat,
      transFat: createRecord.transFat,
      polyunsaturatedFat: createRecord.polyunsaturatedFat,
      monounsaturatedFat: createRecord.monounsaturatedFat,
      fiber: createRecord.fiber,
      sugar: createRecord.sugar,
      cholesterol: createRecord.cholesterol,
      sodium: createRecord.sodium,
      calcium: createRecord.calcium,
      iron: createRecord.iron,
      potassium: createRecord.potassium,
      magnesium: createRecord.magnesium,
      zinc: createRecord.zinc,
      vitaminA: createRecord.vitaminA,
      vitaminB6: createRecord.vitaminB6,
      vitaminB12: createRecord.vitaminB12,
      vitaminC: createRecord.vitaminC,
      vitaminD: createRecord.vitaminD,
      vitaminE: createRecord.vitaminE,
      servingName: createRecord.servingName,
      servingValue: createRecord.servingValue,
      servingUnit: createRecord.servingUnit,
      downvoteCount: createRecord.downvoteCount,
      source: createRecord.source,
      notes: createRecord.notes,
      logCount: 0,
      createdAt: Date(),
      updatedAt: Date()
    )
    
    async let uploadNutritionLabelImageResult = await request.imageStorage.storeAndSignImage(
      imageFile: createNutritionLabelImage,
      storagePath: .nutritionLabel,
      logger: request.logger
    )
    
    async let uploadPackagingImageResult = await request.imageStorage.storeAndSignImage(
      imageFile: createPackagingImage,
      storagePath: .foodPackaging,
      logger: request.logger
    )
    
    newRecord.nutritionLabelImage = await uploadNutritionLabelImageResult.fileName
    newRecord.packagingImage = await uploadPackagingImageResult.fileName

    try await newRecord.save(on: request.db)

    var adminFoodRecord = newRecord.asAdminFoodItemRecord()
    
    // Add the signed URLs to the response
    if let signedNutritionLabelImage = await uploadNutritionLabelImageResult.fileUrl {
      adminFoodRecord?.nutritionLabelImage = signedNutritionLabelImage
    }
    if let signedPackagingImage = await uploadPackagingImageResult.fileUrl {
      adminFoodRecord?.packagingImage = signedPackagingImage
    }

    return AdminCreateFoodItemResponse(foodItemRecord: adminFoodRecord)
  }

  private static func validateCreateFoodRecord(_ createRecord: AdminFoodItemRecord) throws {
    // Validate required fields
    if createRecord.name == nil {
      throw Abort(.badRequest, reason: "name must be present")
    }
    
    // Validate all nutritional values are non-negative in one error message
    var negativeFields: [String] = []
    
    let keyPathsToValidate: [KeyPath<AdminFoodItemRecord, Double?>] = [
      \.calories,
      \.protein, 
      \.carbohydrates,
      \.fat,
      \.saturatedFat,
      \.transFat,
      \.polyunsaturatedFat,
      \.monounsaturatedFat,
      \.fiber,
      \.sugar,
      \.cholesterol,
      \.sodium,
      \.calcium,
      \.iron,
      \.potassium,
      \.magnesium,
      \.zinc,
      \.vitaminA,
      \.vitaminB6,
      \.vitaminB12,
      \.vitaminC,
      \.vitaminD,
      \.vitaminE
    ]
    
    for keyPath in keyPathsToValidate {
      if let value = createRecord[keyPath: keyPath], value < 0 {
        negativeFields.append(String(String(describing: keyPath).split(separator: ".").last ?? ""))
      }
    }
    
    if !negativeFields.isEmpty {
      let fieldsString = negativeFields.joined(separator: ", ")
      throw Abort(.badRequest, reason: "The following fields cannot be negative: \(fieldsString)")
    }
  }

  @Sendable
  func updateFood(_ request: Request) async throws -> AdminUpdateFoodItemResponse {
    let requestBody = try request.content.decode(AdminUpdateFoodItemRequest.self)
    let updateRecord = requestBody.foodItemRecord
    let updateNutritionLabelImage = requestBody.nutritionLabelImage
    let updatePackagingImage = requestBody.packagingImage

    guard let existingRecord = try await FoodItemRecord.find(updateRecord.id.value, on: request.db) else {
      throw Abort(.notFound)
    }

    if let name = updateRecord.name {
      existingRecord.name = name
    }

    existingRecord.state = updateRecord.state.asState()
    existingRecord.brandName = updateRecord.brandName
    existingRecord.flavour = updateRecord.flavour
    if let category = updateRecord.category {
      existingRecord.category = category.asCategory()
    }
    existingRecord.barcode = updateRecord.barcode
    existingRecord.ingredients = updateRecord.ingredients
    if let country = updateRecord.country {
      existingRecord.country = country
    }
    existingRecord.calories = updateRecord.calories
    existingRecord.protein = updateRecord.protein
    existingRecord.carbohydrates = updateRecord.carbohydrates
    existingRecord.fat = updateRecord.fat
    existingRecord.saturatedFat = updateRecord.saturatedFat
    existingRecord.transFat = updateRecord.transFat
    existingRecord.polyunsaturatedFat = updateRecord.polyunsaturatedFat
    existingRecord.monounsaturatedFat = updateRecord.monounsaturatedFat
    existingRecord.fiber = updateRecord.fiber
    existingRecord.sugar = updateRecord.sugar
    existingRecord.cholesterol = updateRecord.cholesterol
    existingRecord.sodium = updateRecord.sodium
    existingRecord.calcium = updateRecord.calcium
    existingRecord.iron = updateRecord.iron
    existingRecord.potassium = updateRecord.potassium
    existingRecord.magnesium = updateRecord.magnesium
    existingRecord.zinc = updateRecord.zinc
    existingRecord.vitaminA = updateRecord.vitaminA
    existingRecord.vitaminB6 = updateRecord.vitaminB6
    existingRecord.vitaminB12 = updateRecord.vitaminB12
    existingRecord.vitaminC = updateRecord.vitaminC
    existingRecord.vitaminD = updateRecord.vitaminD
    existingRecord.vitaminE = updateRecord.vitaminE
    existingRecord.servingName = updateRecord.servingName
    existingRecord.servingValue = updateRecord.servingValue
    existingRecord.servingUnit = updateRecord.servingUnit
    existingRecord.downvoteCount = updateRecord.downvoteCount
    existingRecord.source = updateRecord.source
    existingRecord.notes = updateRecord.notes

    /// When there is an updated Nutrition Label, store in S3, replace filePath in DB, sign a URL, and return the URL in the admin response.
    var signedNutritionLabelImage: URL?
    if let updateNutritionLabelImage {
      let imageMetadata = try await request.imageStorage.store(
        image: updateNutritionLabelImage,
        path: .nutritionLabel
      )
      signedNutritionLabelImage = try await request.imageStorage.generateImageURL(
        fileName: imageMetadata.filename,
        path: .nutritionLabel,
        expiration: .hours(2)
      )
      existingRecord.nutritionLabelImage = imageMetadata.filename
    }

    /// When there is an updated Packaging Image, store in S3, replace filePath in DB, sign a URL, and return the URL in the admin response.
    var signedPackagingImage: URL?
    if let updatePackagingImage {
      let imageMetadata = try await request.imageStorage.store(
        image: updatePackagingImage,
        path: .foodPackaging
      )
      signedPackagingImage = try await request.imageStorage.generateImageURL(
        fileName: imageMetadata.filename,
        path: .foodPackaging,
        expiration: .hours(2)
      )
      existingRecord.packagingImage = imageMetadata.filename
    }

    try await existingRecord.save(on: request.db)

    var adminFoodRecord = existingRecord.asAdminFoodItemRecord()

    if let signedNutritionLabelImage {
      adminFoodRecord?.nutritionLabelImage = signedNutritionLabelImage
    } else {
      // Copy over existing signed URL.
      adminFoodRecord?.nutritionLabelImage = updateRecord.nutritionLabelImage
    }
    if let signedPackagingImage {
      adminFoodRecord?.packagingImage = signedPackagingImage
    } else {
      // Copy over existing signed URL.
      adminFoodRecord?.packagingImage = updateRecord.packagingImage
    }

    return AdminUpdateFoodItemResponse(
      foodItemRecord: adminFoodRecord
    )
  }

  @Sendable
  func deleteFood(_ request: Request) async throws -> Response {
    guard let id = request.parameters.get("id") else {
      throw Abort(.badRequest, reason: "Missing id.")
    }

    guard let record = try await FoodItemRecord.find(id, on: request.db) else {
      throw Abort(.notFound)
    }

    try await record.delete(on: request.db)

    return Response(status: .ok) // 200
  }

  @Sendable
  func searchFood(_ request: Request) async throws -> AdminSearchFoodItemResponse {
    let requestQuery = try request.query.decode(AdminSearchFoodItemGetRequest.self)
    let query = requestQuery.query

    let records = try await request.foodDatabaseService.adminSearchFoods(query: query)

    return AdminSearchFoodItemResponse(foodItemRecords: records)
  }
  
  @Sendable
  func getAccuracyReport(_ request: Request) async throws -> AdminAccuracyReportGetResponse {
    let requestQuery = try request.query.decode(AdminAccuracyReportGetRequest.self)
    let foodItemRecordID = FoodItemIdentifier(requestQuery.foodItemRecordID)

    return try await request.foodDatabaseService.getLatestAccuracyReport(forFoodItemWithId: foodItemRecordID)
  }

  @Sendable
  func evaluateAccuracy(_ request: Request) async throws -> AdminAccuracyReportGetResponse {
    let requestBody = try request.content.decode(AdminRegenerateAccuracyReportRequest.self)
    let foodItemId = requestBody.foodItemRecordID
    
    async let foodItemRecord = try await FoodItemRecord.find(foodItemId.value, on: request.db)
    async let issueReportCount = try await FoodItemIssueReport.query(on: request.db).filter(\.$foodItemRecord.$id == foodItemId.value).count()
    async let recentIssueReports = try await FoodItemIssueReport.query(on: request.db).filter(\.$foodItemRecord.$id == foodItemId.value).limit(5).all()
    
    guard let foodItemRecord = try await foodItemRecord else {
      throw Abort(.notFound)
    }
    
    let evaluation = try await request.openAIService.evaluateFoodItemAccuracy(
      foodItemRecord: foodItemRecord,
      totalNumberOfIssueReports: issueReportCount,
      sampleIssueReports: recentIssueReports
    )
    
    // Create and save the accuracy report
    let accuracyReport = FoodItemAccuracyReport(
      id: UUID().uuidString,
      foodItemRecord: foodItemId.value,
      accuracyScore: Double(evaluation.score),
      evaluationNotes: evaluation.notes,
      recommendations: evaluation.recommendations
    )
        
    try await accuracyReport.save(on: request.db)
    
    return AdminAccuracyReportGetResponse(report: .init(
      accuracyScore: accuracyReport.accuracyScore,
      evaluationNotes: accuracyReport.evaluationNotes,
      createdAt: accuracyReport.createdAt
    ))
  }
  
  @Sendable
  func getDuplicateGroups(_ request: Request) async throws -> DuplicateGroupsResponse {
    let query = try request.query.decode(DuplicateGroupsRequest.self)
    
    return try await request.foodDatabaseService.findDuplicateGroups(
      limit: query.limit ?? 50,
      offset: query.offset ?? 0,
      minimumDuplicates: query.minimumDuplicates ?? 2,
      category: query.category?.asCategory(),
      state: query.state?.asState()
    )
  }
  
  @Sendable
  func getDuplicatesForItem(_ request: Request) async throws -> ItemDuplicatesResponse {
    guard let id = request.parameters.get("id") else {
      throw Abort(.badRequest, reason: "Missing id.")
    }
    
    let query = try request.query.decode(ItemDuplicatesRequest.self)
    let foodID = FoodItemIdentifier(id)
    
    return try await request.foodDatabaseService.findDuplicatesForItem(
      foodID: foodID,
      similarityThreshold: query.similarityThreshold ?? 0.3,
      limit: query.limit ?? 20
    )
  }
  
  @Sendable
  func mergeFoodItems(_ request: Request) async throws -> MergeFoodItemsResponse {
    let requestBody = try request.content.decode(MergeFoodItemsRequest.self)
    
    return try await request.foodDatabaseService.mergeFoodItems(
      primaryItemId: requestBody.primaryItemId,
      itemsToMerge: requestBody.itemsToMerge,
      mergedData: requestBody.mergedItem
    )
  }
  
  @Sendable
  func markItemsAsDistinct(_ request: Request) async throws -> MarkItemsDistinctResponse {
    let requestBody = try request.content.decode(MarkItemsDistinctRequest.self)
    
    // Get admin user ID from authenticated request
    let adminUser = try request.auth.require(AdminUser.self)
    guard let adminUserId = adminUser.id else {
      throw Abort(.unauthorized, reason: "Admin user ID not found")
    }
    
    try await request.foodDatabaseService.markItemsAsDistinct(
      foodItemId: requestBody.foodItemId,
      duplicateItemId: requestBody.duplicateItemId,
      adminUserId: adminUserId.value
    )
    
    return MarkItemsDistinctResponse(
      success: true,
      message: "Items marked as distinct successfully"
    )
  }
  
  @Sendable
  func runDuplicateDetection(_ request: Request) async throws -> RunDuplicateDetectionResponse {
    request.logger.info("Admin triggered manual duplicate detection")
    
    let duplicateService = DuplicateDetectionService(
      db: request.db,
      logger: request.logger
    )
    
    try await duplicateService.processNextBatch()
    
    // Get statistics about processed items
    let totalItems = try await FoodItemRecord.query(on: request.db).count()
    let processedItems = try await FoodItemRecord.query(on: request.db)
      .filter(\.$duplicateLastProcessed != nil)
      .count()
    let itemsWithDuplicates = try await FoodItemRecord.query(on: request.db)
      .filter(\.$duplicateScore != nil)
      .filter(\.$duplicateScore > 0)
      .count()
    
    return RunDuplicateDetectionResponse(
      success: true,
      message: "Duplicate detection completed",
      totalItems: totalItems,
      processedItems: processedItems,
      itemsWithDuplicates: itemsWithDuplicates
    )
  }

  // MARK: - Issue Reports

  @Sendable
  func getIssueReports(_ request: Request) async throws -> AdminFoodItemIssueReportsResponse {
    guard let foodItemRecordID = request.query[String.self, at: "food_item_record_id"] else {
      throw Abort(.badRequest, reason: "Missing food_item_record_id query parameter")
    }

    let foodID = FoodItemIdentifier(foodItemRecordID)
    let reports = try await request.foodDatabaseService.getIssueReportsForFoodItem(foodID: foodID)

    return AdminFoodItemIssueReportsResponse(issueReports: reports)
  }

  @Sendable
  func applyIssueReport(_ request: Request) async throws -> AdminApplyIssueReportResponse {
    let requestBody = try request.content.decode(AdminApplyIssueReportRequest.self)

    let result = try await request.foodDatabaseService.applyIssueReport(
      reportID: requestBody.issueReportID,
      fieldsToApply: requestBody.fieldsToApply
    )

    // Send push notification if user exists
    if let user = result.user {
      if let deviceToken = user.apnsDeviceToken {
        do {
          try await request.notificationService.sendIssueReportAcceptedNotification(
            to: user,
            deviceToken: deviceToken,
            foodItemName: result.foodItemName
          )
          request.logger.info("Sent issue report accepted notification to user \(user.id?.value ?? "unknown")")
        } catch {
          request.logger.error("Failed to send issue report notification: \(error)")
        }
      } else {
        request.logger.info("User \(user.id?.value ?? "unknown") has no APNS device token, skipping notification")
      }
    } else {
      request.logger.info("No user associated with issue report, skipping notification")
    }

    return AdminApplyIssueReportResponse(foodItemRecord: result.foodItemRecord)
  }

  @Sendable
  func deleteIssueReport(_ request: Request) async throws -> HTTPStatus {
    guard let reportID = request.parameters.get("id") else {
      throw Abort(.badRequest, reason: "Missing id parameter")
    }

    try await request.foodDatabaseService.deleteIssueReport(reportID: reportID)
    return .ok
  }
}

private extension ImageStorage {
  func storeAndSignImage(
    imageFile: ImageFile?,
    storagePath: StoragePath,
    logger: Logger
  ) async -> (fileName: String?, fileUrl: URL?) {
    guard let imageFile else {
      return (fileName: nil, fileUrl: nil)
    }
    
    do {
      let imageMetadata = try await store(
        image: imageFile,
        path: storagePath
      )
      
      let signedUrl = try await generateImageURL(
        fileName: imageMetadata.filename,
        path: .nutritionLabel,
        expiration: .hours(2)
      )

      return (fileName: imageMetadata.filename, fileUrl: signedUrl)
    } catch {
      logger.log(level: .warning, "Failed to store and sign image for \(storagePath)")
      return (fileName: nil, fileUrl: nil)
    }
  }
}
