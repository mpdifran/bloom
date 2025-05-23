//
//  DetectedFood.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-17.
//

import Foundation
import BloomModel

struct DetectedFood: Codable, Hashable, Sendable {
  let name: String
  let meal: SocketMessage.DetectedFood.Meal
  let foodItems: [FoodItem]
}

extension DetectedFood {
  struct FoodItem: Codable, Hashable, Sendable {
    let name: String
    let brandName: String?
    let flavour: String?
    let servingName: String
    let servingCount: Double
    let calories: Quantity
    let fat: Quantity?
    let carbohydrates: Quantity?
    let protein: Quantity?
    let saturatedFat: Quantity?
    let transFat: Quantity?
    let polyunsaturatedFat: Quantity?
    let monounsaturatedFat: Quantity?
    let fiber: Quantity?
    let sugar: Quantity?
    let cholesterol: Quantity?
    let sodium: Quantity?
    let calcium: Quantity?
    let iron: Quantity?
    let potassium: Quantity?
    let magnesium: Quantity?
    let zinc: Quantity?
    let vitaminA: Quantity?
    let vitaminB6: Quantity?
    let vitaminB12: Quantity?
    let vitaminC: Quantity?
    let vitaminD: Quantity?
    let vitaminE: Quantity?
  }

  struct Quantity: Codable, Hashable, Sendable {
    let value: Double
    let unit: String
  }
}

extension DetectedFood.FoodItem {
  init(from decoder: Decoder) throws {
    enum Key: String, CodingKey {
      case name, brandName, flavour, servingName, servingCount,
           calories, fat, carbohydrates, protein,
           saturatedFat, transFat, polyunsaturatedFat, monounsaturatedFat,
           fiber, sugar, cholesterol, sodium, calcium, iron,
           potassium, magnesium, zinc,
           vitaminA, vitaminB6, vitaminB12, vitaminC, vitaminD, vitaminE
    }
    enum QuantityKey: String, CodingKey { case value, unit }

    func defaultUnit(for nutrient: String) -> String {
      switch nutrient {
      case "calories": return "kcal"
      case "fat", "carbohydrates", "protein",
           "saturatedFat", "transFat",
           "polyunsaturatedFat", "monounsaturatedFat",
           "fiber", "sugar": return "g"
      case "cholesterol", "sodium", "calcium", "iron",
           "potassium", "magnesium", "zinc": return "mg"
      case "vitaminB6", "vitaminC", "vitaminE": return "mg"
      case "vitaminA", "vitaminB12", "vitaminD": return "mcg"
      default: return ""
      }
    }

    let container = try decoder.container(keyedBy: Key.self)
    let name = try container.decode(String.self, forKey: .name)
    let brandName = try container.decodeIfPresent(String.self, forKey: .brandName)
    let flavour = try container.decodeIfPresent(String.self, forKey: .flavour)
    let servingName = try container.decode(String.self, forKey: .servingName)
    let servingCount = try container.decode(Double.self, forKey: .servingCount)

    func decodeQuantity(_ key: Key) throws -> DetectedFood.Quantity? {
      if let nested = try? container.nestedContainer(keyedBy: QuantityKey.self, forKey: key) {
        let value = try nested.decode(Double.self, forKey: .value)
        let unit = try nested.decode(String.self, forKey: .unit)
        return DetectedFood.Quantity(value: value, unit: unit)
      } else if let val = try? container.decode(Double.self, forKey: key) {
        return DetectedFood.Quantity(value: val, unit: defaultUnit(for: key.stringValue))
      }
      return nil
    }

    let calories = try decodeQuantity(.calories)!
    let fat = try decodeQuantity(.fat)
    let carbohydrates = try decodeQuantity(.carbohydrates)
    let protein = try decodeQuantity(.protein)
    let saturatedFat = try decodeQuantity(.saturatedFat)
    let transFat = try decodeQuantity(.transFat)
    let polyunsaturatedFat = try decodeQuantity(.polyunsaturatedFat)
    let monounsaturatedFat = try decodeQuantity(.monounsaturatedFat)
    let fiber = try decodeQuantity(.fiber)
    let sugar = try decodeQuantity(.sugar)
    let cholesterol = try decodeQuantity(.cholesterol)
    let sodium = try decodeQuantity(.sodium)
    let calcium = try decodeQuantity(.calcium)
    let iron = try decodeQuantity(.iron)
    let potassium = try decodeQuantity(.potassium)
    let magnesium = try decodeQuantity(.magnesium)
    let zinc = try decodeQuantity(.zinc)
    let vitaminA = try decodeQuantity(.vitaminA)
    let vitaminB6 = try decodeQuantity(.vitaminB6)
    let vitaminB12 = try decodeQuantity(.vitaminB12)
    let vitaminC = try decodeQuantity(.vitaminC)
    let vitaminD = try decodeQuantity(.vitaminD)
    let vitaminE = try decodeQuantity(.vitaminE)

    self.init(
      name: name,
      brandName: brandName,
      flavour: flavour,
      servingName: servingName,
      servingCount: servingCount,
      calories: calories,
      fat: fat,
      carbohydrates: carbohydrates,
      protein: protein,
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
      vitaminE: vitaminE
    )
  }
}
