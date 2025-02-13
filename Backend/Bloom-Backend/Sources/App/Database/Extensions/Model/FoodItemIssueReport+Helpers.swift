//
//  FoodItemIssueReport+Helpers.swift
//  Bloom-Backend
//
//  Created by Haocen Jiang on 2025-02-10.
//

import Foundation

extension FoodItemIssueReport {
  // consider using libraries like https://github.com/pointfreeco/swift-custom-dump in the future
  func prettyPrint() -> String {
    """
    FoodItemIssueReport(
      id: \(id ?? "nil"),
      name: \(name ?? "nil"),
      brandName: \(brandName ?? "nil"),
      flavour: \(flavour ?? "nil"),
      nutritionLabelImage: \(nutritionLabelImage ?? "nil"),
      packagingImage: \(packagingImage ?? "nil"),
      ingredients: \(ingredients ?? "nil"),
      calories: \(calories?.description ?? "nil"),
      protein: \(protein?.description ?? "nil"),
      carbohydrates: \(carbohydrates?.description ?? "nil"),
      fat: \(fat?.description ?? "nil"),
      saturatedFat: \(saturatedFat?.description ?? "nil"),
      transFat: \(transFat?.description ?? "nil"),
      polyunsaturatedFat: \(polyunsaturatedFat?.description ?? "nil"),
      monounsaturatedFat: \(monounsaturatedFat?.description ?? "nil"),
      fiber: \(fiber?.description ?? "nil"),
      sugar: \(sugar?.description ?? "nil"),
      cholesterol: \(cholesterol?.description ?? "nil"),
      sodium: \(sodium?.description ?? "nil"),
      calcium: \(calcium?.description ?? "nil"),
      iron: \(iron?.description ?? "nil"),
      potassium: \(potassium?.description ?? "nil"),
      magnesium: \(magnesium?.description ?? "nil"),
      zinc: \(zinc?.description ?? "nil"),
      vitaminA: \(vitaminA?.description ?? "nil"),
      vitaminB6: \(vitaminB6?.description ?? "nil"),
      vitaminB12: \(vitaminB12?.description ?? "nil"),
      vitaminC: \(vitaminC?.description ?? "nil"),
      vitaminD: \(vitaminD?.description ?? "nil"),
      vitaminE: \(vitaminE?.description ?? "nil"),
      servingName: \(servingName ?? "nil"),
      servingValue: \(servingValue?.description ?? "nil"),
      servingUnit: \(servingUnit ?? "nil"),
      notes: \(notes ?? "nil"),
      foodItemRecordID: \($foodItemRecord.id)
    )
    """
  }
}

