//
//  FoodItemEntity.swift
//  Bloom
//
//  Created by Claude Code on 2025-10-16.
//

import AppIntents
import Foundation
import DataContainer
import BloomModel

struct FoodItemEntity: AppEntity, Identifiable, Codable {
  let id: String
  let name: String
  let brandName: String?
  let flavour: String?
  let calories: Double?
  let protein: Double?
  let carbs: Double?
  let fat: Double?

  var displayRepresentation: DisplayRepresentation {
    var title = name

    // Add flavour if present and not empty
    if let flavour = flavour, !flavour.isEmpty {
      title += " (\(flavour))"
    }

    // Add brand name if present and not empty
    if let brandName = brandName, !brandName.isEmpty {
      title += " - \(brandName)"
    }

    // Create subtitle with nutrition info
    var subtitle: String?
    if let calories = calories {
      var nutritionParts: [String] = ["\(Int(calories)) cal"]
      if let protein = protein {
        nutritionParts.append("\(Int(protein))g protein")
      }
      if let carbs = carbs {
        nutritionParts.append("\(Int(carbs))g carbs")
      }
      if let fat = fat {
        nutritionParts.append("\(Int(fat))g fat")
      }
      subtitle = nutritionParts.joined(separator: " • ")
    }

    return DisplayRepresentation(
      title: LocalizedStringResource(stringLiteral: title),
      subtitle: subtitle.map { LocalizedStringResource(stringLiteral: $0) },
      image: DisplayRepresentation.Image(systemName: "fork.knife")
    )
  }

  nonisolated(unsafe) static var defaultQuery = FoodItemQuery()
  nonisolated(unsafe) static var typeDisplayRepresentation: TypeDisplayRepresentation = "Food Item"
}

extension FoodItemEntity {
  init(from foodItemDTO: FoodItemDTO) {
    self.id = foodItemDTO.id
    self.name = foodItemDTO.name
    self.brandName = foodItemDTO.brandName.isEmpty ? nil : foodItemDTO.brandName
    self.flavour = foodItemDTO.flavour.isEmpty ? nil : foodItemDTO.flavour
    self.calories = foodItemDTO.calories
    self.protein = foodItemDTO.protein
    self.carbs = foodItemDTO.carbohydrates
    self.fat = foodItemDTO.fat
  }

  init(from foodItem: FoodItem) {
    self.id = foodItem.id.value
    self.name = foodItem.name
    self.brandName = foodItem.brandName
    self.flavour = foodItem.flavour
    self.calories = foodItem.calories?.value
    self.protein = foodItem.protein?.value
    self.carbs = foodItem.carbohydrates?.value
    self.fat = foodItem.fat?.value
  }
}
