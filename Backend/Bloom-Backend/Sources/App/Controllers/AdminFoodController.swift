//
//  AdminFoodController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import Foundation
import BloomModel
import Vapor
import Fluent

struct AdminFoodController {
  private let foodDatabaseService = FoodDatabaseService()
  private let openFoodFactsService = OpenFoodFactsService()
}

extension AdminFoodController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "admin", "food") { food in
      food.post("usda-ingest", use: ingestUSDA)
      food.get("unverified", use: getUnverifiedFoods)
      food.patch("update", use: updateFood)
      food.delete(":id", use: deleteFood)
      food.group("open-food-facts") { foodFacts in
        foodFacts.post("bulk-upload", use: openFoodFactsBulkUpload)
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
    let limit = query.limit ?? 100 // Default to 100 if not provided.

    let foodItemRecords = try await foodDatabaseService.getUnverifiedFoodItemRecords(
      request: request,
      limit: limit
    )

    return UnverifiedFoodItemsResponse(foodItemRecords: foodItemRecords)
  }

  @Sendable
  func updateFood(_ request: Request) async throws -> AdminUpdateFoodItemResponse {
    let requestBody = try request.content.decode(AdminUpdateFoodItemRequest.self)
    let updateRecord = requestBody.foodItemRecord

    guard let existingRecord = try await FoodItemRecord.find(updateRecord.id.value, on: request.db) else {
      throw Abort(.notFound)
    }

    if let name = updateRecord.name {
      existingRecord.name = name
    }
    if let state = updateRecord.state {
      existingRecord.state = state.asState()
    }
    existingRecord.brandName = updateRecord.brandName
    existingRecord.flavour = updateRecord.flavour
    if let category = updateRecord.category {
      existingRecord.category = category.asCategory()
    }
    existingRecord.barcode = updateRecord.barcode
    existingRecord.ingredients = updateRecord.ingredients
    if let country = updateRecord.country {
      existingRecord.country = country.asCountry()
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

    try await existingRecord.save(on: request.db)

    return AdminUpdateFoodItemResponse(
      foodItemRecord: existingRecord.asAdminFoodItemRecord()
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
}

private extension AdminFoodController {

  @Sendable
  func openFoodFactsBulkUpload(_ request: Request) async throws -> AdminOpenFoodFactsBulkUploadResponse {
    let requestBody = try request.content.decode(AdminOpenFoodFactsBulkUploadRequest.self)

    let count = try await openFoodFactsService.bulkUpload(request, items: requestBody.items)

    return AdminOpenFoodFactsBulkUploadResponse(insertedCount: count)
  }
}
