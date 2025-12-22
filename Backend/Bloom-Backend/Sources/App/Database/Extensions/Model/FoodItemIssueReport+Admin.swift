//
//  FoodItemIssueReport+Admin.swift
//  Bloom-Backend
//
//  Created by Claude on 2025-12-22.
//

import AdminBloomModel
import BloomModel
import Foundation

extension FoodItemIssueReport {

  func asAdminFoodItemIssueReport(
    imageStorage: ImageStorage
  ) async throws -> AdminFoodItemIssueReport? {
    guard let id = id else { return nil }

    // Get user name if user is loaded
    var userName: String?
    if let user = $user.wrappedValue {
      let names = [user.givenName, user.familyName].compactMap { $0 }
      userName = names.isEmpty ? nil : names.joined(separator: " ")
    }

    // Generate signed URLs for images
    var nutritionLabelImageURL: URL?
    if let nutritionLabelImage {
      nutritionLabelImageURL = try await imageStorage.generateImageURL(
        fileName: nutritionLabelImage,
        path: .nutritionLabel,
        expiration: .hours(2)
      )
    }

    var packagingImageURL: URL?
    if let packagingImage {
      packagingImageURL = try await imageStorage.generateImageURL(
        fileName: packagingImage,
        path: .foodPackaging,
        expiration: .hours(2)
      )
    }

    return AdminFoodItemIssueReport(
      id: id,
      foodItemRecordID: FoodItemIdentifier($foodItemRecord.id),
      userName: userName,
      userID: $user.id?.value,
      name: name,
      brandName: brandName,
      flavour: flavour,
      nutritionLabelImage: nutritionLabelImageURL,
      packagingImage: packagingImageURL,
      ingredients: ingredients,
      calories: calories,
      protein: protein,
      carbohydrates: carbohydrates,
      fat: fat,
      saturatedFat: saturatedFat,
      transFat: transFat,
      polyunsaturatedFat: polyunsaturatedFat,
      monounsaturatedFat: monounsaturatedFat,
      fiber: fiber,
      sugar: sugar,
      cholesterol: cholesterol,
      sodium: sodium,
      calcium: calcium,
      iron: iron,
      potassium: potassium,
      magnesium: magnesium,
      zinc: zinc,
      vitaminA: vitaminA,
      vitaminB6: vitaminB6,
      vitaminB12: vitaminB12,
      vitaminC: vitaminC,
      vitaminD: vitaminD,
      vitaminE: vitaminE,
      servingName: servingName,
      servingValue: servingValue,
      servingUnit: servingUnit,
      notes: notes,
      createdAt: createdAt
    )
  }
}
