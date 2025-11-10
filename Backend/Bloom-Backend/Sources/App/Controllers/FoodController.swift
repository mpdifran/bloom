//
//  FoodController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation
import Vapor
import BloomModel

// MARK: - FoodController

struct FoodController { }

// MARK: - RouteCollection

extension FoodController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.auth(using: UserToken.self) {
      $0.group("v1") {
        $0.group("food") {
          $0.post("autocomplete", use: autocomplete)
          $0.post("estimate", use: estimateFoodCalories)
          $0.post("search", use: searchFoods)
          $0.post("upload", use: uploadNewFood)
          $0.post("mark-as-inaccurate", use: markAsInaccurate)
          $0.post("submit-food-item-issue", use: submitFoodItemIssue)
          $0.post("track-log", use: trackLog)
          $0.post("magic-scan-upload", use: uploadMagicScan)
          $0.post("magic-scan-status", use: checkMagicScanStatus)
          $0.post("magic-scan-cancel", use: cancelMagicScan)
          $0.get(":id", use: getFoodItemById)
        }
      }
      $0.group("v2") {
        $0.group("food") {
          $0.post("estimate", use: estimateFoodCaloriesV2)
        }
      }
    }
  }
}

// MARK: - Route Handlers V1

extension FoodController {

  @Sendable
  func autocomplete(_ request: Request) async throws -> FoodAutocompleteResponse {
//    let requestBody = try request.content.decode(FoodAutocompleteRequest.self)
//    let tokens = try await edamamService.autocomplete(
//      request: request,
//      query: requestBody.query
//    )

    return FoodAutocompleteResponse(tokens: [])
  }

  @Sendable
  func searchFoods(_ request: Request) async throws -> FoodSearchResponse {
    let sections = try await searchFoodsLocalDatabase(request)
    return FoodSearchResponse(sections: sections)
  }

  @Sendable
  func uploadNewFood(_ request: Request) async throws -> UploadNewFoodResponse {
    let requestBody = try request.content.decode(UploadNewFoodRequest.self)

    let existingFoodItems = try await request.foodDatabaseService.searchFoods(barcode: requestBody.barcode)

    // Both country and barcode need to match for it to be considered the same.
    if let foodItem = existingFoodItems.first(where: { $0.country == requestBody.country }) {
      do {
        // Try updating images if they're missing.
        try await request.foodDatabaseService.addProductImagesIfMissing(
          foodID: foodItem.id,
          nutritionImage: requestBody.nutritionLabelImage,
          packagingImage: requestBody.packagingImage
        )
      } catch {
        request.logger.error(error)
      }

      return UploadNewFoodResponse(
        result: .foodLogged,
        foodItem: foodItem
      )
    }

    let nutritionLabelMetadata = try await request.imageStorage.store(
      image: requestBody.nutritionLabelImage,
      path: .nutritionLabel
    )
    let packagingMetadata = try await request.imageStorage.store(
      image: requestBody.packagingImage,
      path: .foodPackaging
    )

    do {
      let (foodItemRecord, result) = try await request.openAIService.parseNewFoodItem(
        barCode: requestBody.barcode,
        country: requestBody.country,
        nutritionLabelMetadata: nutritionLabelMetadata,
        packagingMetadata: packagingMetadata
      )

      try await foodItemRecord?.save(on: request.db)

      let foodItem = foodItemRecord?.asFoodItem()

      return UploadNewFoodResponse(
        result: result,
        foodItem: foodItem
      )
    } catch {
      // TODO: Delete nutritionLabelMetadata and packagingMetadata from S3.

      throw error
    }
  }

  @Sendable
  func estimateFoodCalories(_ request: Request) async throws -> EstimateFoodCaloriesResponse {
    let requestBody = try request.content.decode(EstimateFoodCaloriesRequest.self)

    if let foodImage = requestBody.foodImage {
      guard let foodEstimate = await request.openAIService.estimateCalories(
        foodImageFile: foodImage,
        foodDescription: requestBody.foodDescription
      ) else {
        throw Abort(.internalServerError)
      }

      let servings = foodEstimate.foodItems.map { $0.asServing() }
      let suggestedServings = foodEstimate.optionalFoodItems?.map { $0.asServing() } ?? []

      return EstimateFoodCaloriesResponse(
        name: foodEstimate.name,
        servings: servings,
        suggestedServings: suggestedServings
      )
    } else if let textDescription = requestBody.foodDescription {
      guard let foodEstimate = await request.openAIService.estimateCalories(textDescription: textDescription) else {
        throw Abort(.internalServerError)
      }

      let servings = foodEstimate.foodItems.map { $0.asServing() }
      let suggestedServings = foodEstimate.optionalFoodItems?.map { $0.asServing() } ?? []

      return EstimateFoodCaloriesResponse(
        name: foodEstimate.name,
        servings: servings,
        suggestedServings: suggestedServings
      )
    }

    throw Abort(.badRequest)
  }

  @Sendable
  func markAsInaccurate(_ request: Request) async throws -> Response {
    let requestBody = try request.content.decode(MarkFoodInaccurateRequest.self)

    try await request.foodDatabaseService.markFoodAsInaccurate(foodID: requestBody.foodId)

    return Response(status: .ok)
  }

  @Sendable
  func submitFoodItemIssue(_ request: Request) async throws -> Response {
    let user = try request.auth.require(User.self)
    let requestBody = try request.content.decode(SubmitFoodItemIssueRequest.self)


    try await request.foodDatabaseService.submitFoodItemIssueReport(
      user: user,
      foodItemIssue: requestBody.foodItemIssue
    )

    return Response(status: .ok)
  }

  @Sendable
  func trackLog(_ request: Request) async throws -> Response {
    let requestBody = try request.content.decode(TrackFoodLogRequest.self)

    try await request.foodDatabaseService.incrementLogCount(foodIDs: requestBody.foodIds)

    return Response(status: .ok)
  }

  @Sendable
  func getFoodItemById(_ request: Request) async throws -> GetFoodItemResponse {
    guard let foodId = request.parameters.get("id") else {
      throw Abort(.badRequest)
    }

    guard let foodItemRecord = try await FoodItemRecord.find(foodId, on: request.db) else {
      throw Abort(.notFound, reason: "Food item not found")
    }

    guard let foodItem = foodItemRecord.asFoodItem() else {
      throw Abort(.internalServerError, reason: "Failed to convert food item")
    }

    return GetFoodItemResponse(foodItem: foodItem)
  }

  @Sendable
  func uploadMagicScan(_ request: Request) async throws -> MagicScanUploadResponse {
    let user = try request.auth.require(User.self)
    let requestBody = try request.content.decode(MagicScanUploadRequest.self)

    guard let userId = user.id else {
      throw Abort(.unauthorized, reason: "User ID not found")
    }

    // Store image to S3 if provided
    let imageFileName: String?
    if let foodImage = requestBody.foodImage {
      let imageMetadata = try await request.imageStorage.store(
        image: foodImage,
        path: .magicScanner
      )
      imageFileName = imageMetadata.filename
    } else {
      imageFileName = nil
    }

    // Create job in Redis
    try await request.magicScanJobManager.createJob(
      processingIdentifier: requestBody.processingIdentifier,
      userId: userId,
      imageFileName: imageFileName,
      contextText: requestBody.contextText
    )

    // Trigger background processing
    Task {
      await request.magicScanJobManager.processJob(
        processingIdentifier: requestBody.processingIdentifier,
        imageStorage: request.imageStorage,
        openAIService: request.openAIService,
        db: request.db,
        application: request.application
      )
    }

    return MagicScanUploadResponse(
      processingIdentifier: requestBody.processingIdentifier,
      status: .pending
    )
  }

  @Sendable
  func checkMagicScanStatus(_ request: Request) async throws -> MagicScanStatusResponse {
    let requestBody = try request.content.decode(MagicScanStatusRequest.self)

    var results: [MagicScanStatusResponse.Result] = []

    for processingIdentifier in requestBody.processingIdentifiers {
      guard let job = try await request.magicScanJobManager.getJob(
        processingIdentifier: processingIdentifier
      ) else {
        // Job not found - return notFound status so client can re-upload
        let result = MagicScanStatusResponse.Result(
          processingIdentifier: processingIdentifier,
          status: .notFound,
          servings: nil,
          errorMessage: "Processing record not found - please retry upload"
        )
        results.append(result)
        continue
      }

      var servings: [MagicScanStatusResponse.Serving]?
      if let servingsJson = job.servingsJson,
         let servingsData = servingsJson.data(using: .utf8) {
        servings = try? JSONDecoder.bloomModel.decode(
          [MagicScanStatusResponse.Serving].self,
          from: servingsData
        )
      }

      // Convert string status to enum, skip if invalid
      guard let status = MagicScanStatus(rawValue: job.status) else {
        continue
      }

      let result = MagicScanStatusResponse.Result(
        processingIdentifier: processingIdentifier,
        status: status,
        servings: servings,
        errorMessage: job.errorMessage
      )
      results.append(result)
    }

    return MagicScanStatusResponse(results: results)
  }

  @Sendable
  func cancelMagicScan(_ request: Request) async throws -> Response {
    let requestBody = try request.content.decode(MagicScanCancelRequest.self)

    try await request.magicScanJobManager.cancelJob(
      processingIdentifier: requestBody.processingIdentifier
    )

    return Response(status: .ok)
  }
}

// MARK: - Route Handlers V2

extension FoodController {

  @Sendable
  func estimateFoodCaloriesV2(_ request: Request) async throws -> EstimateFoodCaloriesResponse {
    let requestBody = try request.content.decode(EstimateFoodCaloriesRequest.self)

    if let foodImage = requestBody.foodImage {
      guard let foodEstimate = await request.openAIService.estimateCaloriesV2(
        foodImageFile: foodImage,
        foodDescription: requestBody.foodDescription
      ) else {
        throw Abort(.internalServerError)
      }

      let servings = foodEstimate.foodItems.map { $0.asServing() }
      let suggestedServings = foodEstimate.optionalFoodItems?.map { $0.asServing() } ?? []

      return EstimateFoodCaloriesResponse(
        name: foodEstimate.name,
        servings: servings,
        suggestedServings: suggestedServings
      )
    } else if let textDescription = requestBody.foodDescription {
      guard let foodEstimate = await request.openAIService.estimateCaloriesV2(textDescription: textDescription) else {
        throw Abort(.internalServerError)
      }

      let servings = foodEstimate.foodItems.map { $0.asServing() }
      let suggestedServings = foodEstimate.optionalFoodItems?.map { $0.asServing() } ?? []

      return EstimateFoodCaloriesResponse(
        name: foodEstimate.name,
        servings: servings,
        suggestedServings: suggestedServings
      )
    }

    throw Abort(.badRequest)
  }
}

// MARK: - Private Methods

private extension FoodController {

  func searchFoodsLocalDatabase(_ request: Request) async throws -> [FoodSearchResponse.Section] {
    let requestBody = try request.content.decode(FoodSearchRequest.self)

    if let barcode = requestBody.upcCode {
      do {
        let sections = await searchFoodsBarcodeLocalDatabase(request, barcode: barcode)
        if sections.isNotEmpty {
          return sections
        } else {
          let foodItems = try await request.openFoodFactsService.insertProduct(barcode: barcode)
          return [
            FoodSearchResponse.Section(
              title: "Matched Barcode",
              index: 0,
              category: .branded,
              foods: foodItems
            )
          ]
        }
      } catch {
        request.logger.error(error)
      }
    } else if let name = requestBody.name {
      return await searchFoodsByNameLocalDatabase(
        request,
        name: name,
        country: requestBody.country ?? "usa"
      )
    } else {
      throw Abort(.badRequest)
    }

    return []
  }

  func searchFoodsBarcodeLocalDatabase(_ request: Request, barcode: String) async -> [FoodSearchResponse.Section] {
    do {
      let foodItems = try await request.foodDatabaseService.searchFoods(barcode: barcode)

      guard foodItems.isNotEmpty else { return [] }

      let section = FoodSearchResponse.Section(
        title: "Matched Barcode",
        index: 0,
        category: .branded,
        foods: foodItems
      )

      return [section]
    } catch {
      request.logger.error(error)
    }
    return []
  }

  func searchFoodsByNameLocalDatabase(
    _ request: Request,
    name: String,
    country: String
  ) async -> [FoodSearchResponse.Section] {
    do {
      let foodDatabaseService = request.foodDatabaseService

      let foodItems = try await foodDatabaseService.searchFoods(
        query: name,
        preferredCountry: country,
        limit: 20
      )

      guard foodItems.isNotEmpty else { return [] }

      let section = FoodSearchResponse.Section(
        title: "Branded",
        index: 0,
        category: .branded,
        foods: foodItems
      )

      return [section]
    } catch {
      request.logger.error(error)
    }

    return []
  }
}
