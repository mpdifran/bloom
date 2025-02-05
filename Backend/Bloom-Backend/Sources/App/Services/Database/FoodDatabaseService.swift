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

struct FoodDatabaseService { }

extension FoodDatabaseService {

  func searchFoods(
    request: Request,
    query: String,
    category: FoodItemRecord.Category,
    preferredCountry: FoodItemRecord.Country,
    limit: Int
  ) async throws -> [FoodItem] {
    guard !query.isEmpty else { return [] }

    guard let sqlDatabase = request.db as? SQLDatabase else {
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
                   CASE WHEN country = \(bind: preferredCountry.rawValue)::country THEN 1.1 ELSE 1.0 END AS rank
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

  func searchFoods(request: Request, barcode: String) async throws -> [FoodItem] {
    guard !barcode.isEmpty else { return [] }

    guard let sqlDatabase = request.db as? SQLDatabase else {
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
    request: Request,
    limit: Int
  ) async throws -> [AdminFoodItemRecord] {
    guard let sqlDatabase = request.db as? SQLDatabase else {
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

    return try await createAdminRecords(request, from: results)
  }

  func adminSearchFoods(request: Request, query: String) async throws -> [AdminFoodItemRecord] {
    guard let sqlDatabase = request.db as? SQLDatabase else {
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

    return try await createAdminRecords(request, from: results)
  }

  func markFoodAsInaccurate(request: Request, foodID: FoodItemIdentifier) async throws {
    guard let foodItem = try await FoodItemRecord.query(on: request.db)
      .filter(\.$id == foodID.value)
      .first() else {
      throw Abort(.noContent)
    }

    var downvoteCount = foodItem.downvoteCount ?? 0
    downvoteCount += 1
    foodItem.downvoteCount = downvoteCount

    try await foodItem.save(on: request.db)
  }

  func submitFoodItemIssueReport(_ request: Request, foodItemIssue: FoodItemIssue) async throws {
    let user = try request.auth.require(User.self)

    // Save images
    let packagingImageFileName: String?
    let nutritionLabelImageFileName: String?
    if let packagingImage = foodItemIssue.packagingImage {
      let imageMetadata = try await request.imageStorage.store(
        image: packagingImage,
        path: .foodPackaging
      )
      packagingImageFileName = imageMetadata.filename
    } else {
      packagingImageFileName = nil
    }
    if let nutritionImage = foodItemIssue.nutritionLabelImage {
      let imageMetadata = try await request.imageStorage.store(
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

    try await report.save(on: request.db)
  }

  func addProductImagesIfMissing(
    _ request: Request,
    foodID: FoodItemIdentifier,
    nutritionImage: ImageFile,
    packagingImage: ImageFile
  ) async throws {
    guard let foodItem = try await FoodItemRecord.query(on: request.db)
      .filter(\.$id == foodID.value)
      .first() else {
      throw Abort(.noContent)
    }

    if foodItem.nutritionLabelImage == nil {
      let imageMetadata = try await request.imageStorage.store(
        image: nutritionImage,
        path: .nutritionLabel
      )
      foodItem.nutritionLabelImage = imageMetadata.filename
    }
    if foodItem.packagingImage == nil {
      let imageMetadata = try await request.imageStorage.store(
        image: packagingImage,
        path: .foodPackaging
      )
      foodItem.packagingImage = imageMetadata.filename
    }
    
    try await foodItem.save(on: request.db)
  }
}

private extension FoodDatabaseService {
  /// Map foodItemRecords to adminFoodItemRecords and sign images from S3.
  func createAdminRecords(
    _ request: Request,
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
          imageURL = try await request.imageStorage.generateImageURL(
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
          imageURL = try await request.imageStorage.generateImageURL(
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
