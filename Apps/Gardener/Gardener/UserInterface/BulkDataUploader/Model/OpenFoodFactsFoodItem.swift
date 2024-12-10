//
//  OpenFoodFactsFoodItem.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-12-04.
//

import Foundation

private extension String {
  static let imageBaseS3URL = "https://openfoodfacts-images.s3.eu-west-3.amazonaws.com/data"
}

struct OpenFoodFactsFoodItem: Codable {
  let id: String?
  let productName: String?
  let brands: String?
  let code: String?
  let countriesTags: [String]
  let ingredientsTextEn: String?
  let servingSize: String?
  let servingQuantity: Double?
  let servingQuantityUnit: String?
  let nutriments: Nutriments?
  let images: Images?

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decodeIfPresent(String.self, forKey: .id)
    self.productName = try container.decodeIfPresent(String.self, forKey: .productName)
    self.brands = try container.decodeIfPresent(String.self, forKey: .brands)
    self.code = try container.decodeIfPresent(String.self, forKey: .code)
    self.countriesTags = try container.decode([String].self, forKey: .countriesTags)
    self.ingredientsTextEn = try container.decodeIfPresent(String.self, forKey: .ingredientsTextEn)
    self.servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize)

    if let doubleQuantity = try? container.decodeIfPresent(Double.self, forKey: .servingQuantity) {
      self.servingQuantity = doubleQuantity
    } else if let stringQuantity = try? container.decodeIfPresent(String.self, forKey: .servingQuantity) {
      self.servingQuantity = Double(stringQuantity)
    } else {
      self.servingQuantity = nil
    }
    self.servingQuantityUnit = try container.decodeIfPresent(String.self, forKey: .servingQuantityUnit)
    self.nutriments = try container.decodeIfPresent(OpenFoodFactsFoodItem.Nutriments.self, forKey: .nutriments)
    self.images = try container.decodeIfPresent(OpenFoodFactsFoodItem.Images.self, forKey: .images)
  }
}

extension OpenFoodFactsFoodItem {
  var barcodeSegments: [String]? {
    guard var barcode = id ?? code else { return nil }

    if barcode.count == 8 {
      return [barcode]
    }

    while barcode.count < 13 {
      barcode = "0" + barcode
    }

    let group1 = String(barcode.prefix(3))
    let group2 = String(barcode.dropFirst(3).prefix(3))
    let group3 = String(barcode.dropFirst(6).prefix(3))
    let group4 = String(barcode.dropFirst(9))

    return [group1, group2, group3, group4]
  }

  var frontImageURL: URL? {
    guard
      var url = URL(string: .imageBaseS3URL),
      let barcodeSegments = barcodeSegments
    else { return nil }

    for segment in barcodeSegments {
      url = url.appending(path: segment)
    }

    if let id = images?.front?.imgid {
      url = url.appending(path: "\(id).400.jpg")
    } else if let id = images?.frontEn?.imgid {
      url = url.appending(path: "\(id).400.jpg")
    } else {
      return nil
    }

    return url
  }

  var nutritionImageURL: URL? {
    guard
      var url = URL(string: .imageBaseS3URL),
      let barcodeSegments = barcodeSegments
    else { return nil }

    for segment in barcodeSegments {
      url = url.appending(path: segment)
    }

    if let id = images?.nutrition?.imgid {
      url = url.appending(path: "\(id).400.jpg")
    } else if let id = images?.nutritionEn?.imgid {
      url = url.appending(path: "\(id).400.jpg")
    } else {
      return nil
    }

    return url
  }
}

extension OpenFoodFactsFoodItem {
  struct Images: Codable {
    let front: ImageDetails?
    let frontEn: ImageDetails?
    let nutrition: ImageDetails?
    let nutritionEn: ImageDetails?
  }

  struct ImageDetails: Codable {
    let imgid: String

    init(from decoder: any Decoder) throws {
      let container: KeyedDecodingContainer<OpenFoodFactsFoodItem.ImageDetails.CodingKeys> = try decoder.container(keyedBy: OpenFoodFactsFoodItem.ImageDetails.CodingKeys.self)
      if let id = try? container.decode(String.self, forKey: OpenFoodFactsFoodItem.ImageDetails.CodingKeys.imgid) {
        self.imgid = id
      } else {
        let id = try container.decode(Int.self, forKey: OpenFoodFactsFoodItem.ImageDetails.CodingKeys.imgid)
        self.imgid = String(id)
      }
    }
  }
}

extension OpenFoodFactsFoodItem {
  struct Nutriments: Codable {
    let energyServing: Double?
    let energyUnit: String?
    let proteinsServing: Double?
    let proteinsUnit: String?
    let carbohydratesServing: Double?
    let carbohydratesUnit: String?
    let fatServing: Double?
    let fatUnit: String?
    let saturatedFatServing: Double?
    let saturatedFatUnit: String?
    let transFatServing: Double?
    let transFatUnit: String?
    let polyunsaturatedFatServing: Double?
    let polyunsaturatedFatUnit: String?
    let monounsaturatedFatServing: Double?
    let monounsaturatedFatUnit: String?
    let fiberServing: Double?
    let fiberUnit: String?
    let sugarsServing: Double?
    let sugarsUnit: String?
    let cholesterolServing: Double?
    let cholesterolUnit: String?
    let sodiumServing: Double?
    let sodiumUnit: String?
    let calciumServing: Double?
    let calciumUnit: String?
    let ironServing: Double?
    let ironUnit: String?
    let potassiumServing: Double?
    let potassiumUnit: String?
    let magnesiumServing: Double?
    let magnesiumUnit: String?
    let zincServing: Double?
    let zincUnit: String?
    let vitaminAServing: Double?
    let vitaminAUnit: String?
    let vitaminB6Serving: Double?
    let vitaminB6Unit: String?
    let vitaminB12Serving: Double?
    let vitaminB12Unit: String?
    let vitaminCServing: Double?
    let vitaminCUnit: String?
    let vitaminDServing: Double?
    let vitaminDUnit: String?
    let vitaminEServing: Double?
    let vitaminEUnit: String?

    enum CodingKeys: String, CodingKey {
      case energyServing = "energy-kcalServing"
      case energyUnit
      case proteinsServing
      case proteinsUnit
      case carbohydratesServing
      case carbohydratesUnit
      case fatServing
      case fatUnit
      case saturatedFatServing = "saturated-fatServing"
      case saturatedFatUnit = "saturated-fatUnit"
      case transFatServing = "trans-fatServing"
      case transFatUnit = "trans-fatUnit"
      case polyunsaturatedFatServing = "polyunsaturated-fatServing"
      case polyunsaturatedFatUnit = "polyunsaturated-fatUnit"
      case monounsaturatedFatServing = "monounsaturated-fatServing"
      case monounsaturatedFatUnit = "monounsaturated-fatUnit"
      case fiberServing
      case fiberUnit
      case sugarsServing
      case sugarsUnit
      case cholesterolServing
      case cholesterolUnit
      case sodiumServing
      case sodiumUnit
      case calciumServing
      case calciumUnit
      case ironServing
      case ironUnit
      case potassiumServing
      case potassiumUnit
      case magnesiumServing
      case magnesiumUnit
      case zincServing
      case zincUnit
      case vitaminAServing = "vitamin-aServing"
      case vitaminAUnit = "vitamin-aUnit"
      case vitaminB6Serving = "vitamin-bSserving"
      case vitaminB6Unit = "vitamin-b6Unit"
      case vitaminB12Serving = "vitamin-bS_serving"
      case vitaminB12Unit = "vitamin-b12Unit"
      case vitaminCServing = "vitamin-cServing"
      case vitaminCUnit = "vitamin-cUnit"
      case vitaminDServing = "vitamin-dServing"
      case vitaminDUnit = "vitamin-dUnit"
      case vitaminEServing = "vitamin-eServing"
      case vitaminEUnit = "vitamin-eUnit"
    }
  }
}

extension OpenFoodFactsFoodItem.Nutriments {

  func resolvedMilligramBasedUnit(serving: KeyPath<OpenFoodFactsFoodItem.Nutriments, Double?>, unit: KeyPath<OpenFoodFactsFoodItem.Nutriments, String?>) throws -> Double? {
    guard let value = self[keyPath: serving] else { return nil }

    let unit = self[keyPath: unit]

    switch unit {
    case "g":
      return value * 1000
    case "mg":
      return value
    default:
      throw NSError(description: "Unknown unit \(serving): \(unit ?? "")")
    }
  }

  // https://www.thecalculatorsite.com/articles/units/convert-ui-to-mcg.php
  func resolvedVitaminAServing() throws -> Double? {
    guard let vitaminAServing else { return nil }
    
    if vitaminAUnit == "IU" {
      return vitaminAServing * 0.0003
    } else if let value = try resolvedVitaminServing(serving: \.vitaminAServing, unit: \.vitaminAUnit) {
      return value
    } else {
      throw NSError(description: "Unknown VitaminA unit: \(vitaminAUnit ?? "")")
    }
  }

  func resolvedVitaminB12Serving() throws -> Double? {
    guard let vitaminB12Serving else { return nil }

    if vitaminB12Unit == "µg" {
      return vitaminB12Serving / 1000
    } else if let value = try resolvedVitaminServing(serving: \.vitaminB12Serving, unit: \.vitaminB12Unit) {
      return value
    } else {
      throw NSError(description: "Unknown VitaminB12 unit: \(vitaminB12Unit ?? "")")
    }
  }

  // https://www.thecalculatorsite.com/articles/units/convert-ui-to-mcg.php
  func resolvedVitaminCServing() throws -> Double? {
    guard let vitaminCServing else { return nil }

    if vitaminCUnit == "IU" {
      return vitaminCServing * 0.05
    } else if let value = try resolvedVitaminServing(serving: \.vitaminCServing, unit: \.vitaminCUnit) {
      return value
    } else {
      throw NSError(description: "Unknown VitaminC unit: \(vitaminCUnit ?? "")")
    }
  }

  // https://www.thecalculatorsite.com/articles/units/convert-ui-to-mcg.php
  func resolvedVitaminDServing() throws -> Double? {
    guard let vitaminDServing else { return nil }

    if vitaminDUnit == "IU" {
      return vitaminDServing * 0.000025
    } else if let value = try resolvedVitaminServing(serving: \.vitaminDServing, unit: \.vitaminDUnit) {
      return value
    } else {
      throw NSError(description: "Unknown VitaminD unit: \(vitaminDUnit ?? "")")
    }
  }

  // https://www.thecalculatorsite.com/articles/units/convert-ui-to-mcg.php
  func resolvedVitaminEServing() throws -> Double? {
    guard let vitaminEServing else { return nil }

    if vitaminEUnit == "IU" {
      return vitaminEServing * 0.67
    } else if let value = try resolvedVitaminServing(serving: \.vitaminEServing, unit: \.vitaminEUnit) {
      return value
    } else {
      throw NSError(description: "Unknown VitaminE unit: \(vitaminEUnit ?? "")")
    }
  }

  func resolvedVitaminServing(serving: KeyPath<OpenFoodFactsFoodItem.Nutriments, Double?>, unit: KeyPath<OpenFoodFactsFoodItem.Nutriments, String?>) throws -> Double? {
    guard let value = self[keyPath: serving] else { return nil }

    let unit = self[keyPath: unit]

    switch unit {
    case "g":
      return value * 1000
    case "mg":
      return value
    case "µg":
      return value / 1000
    default:
      throw NSError(description: "Unknown unit \(serving): \(unit ?? "")")
    }
  }

  func equals(keyPath: KeyPath<OpenFoodFactsFoodItem.Nutriments, String?>, unit: String) -> Bool {
    self[keyPath: keyPath] == nil || self[keyPath: keyPath] == unit
  }
}

extension OpenFoodFactsFoodItem {

  var isValid: Bool {
    let validCountries: Set<String> = ["en:canada", "en:Canada", "en:united-states"]

    guard countriesTags.asSet().intersection(validCountries).isNotEmpty else {
      return false
    }

    return (id ?? code) != nil &&
    servingQuantity != nil &&
    servingQuantityUnit != nil &&
    nutriments?.energyServing != nil
  }

  var hasValidNutrimentUnit: Bool {
    guard let nutriments else { return true }

    return nutriments.equals(keyPath: \.proteinsUnit, unit: "g") &&
    nutriments.equals(keyPath: \.carbohydratesUnit, unit: "g") &&
    nutriments.equals(keyPath: \.fatUnit, unit: "g") &&
    nutriments.equals(keyPath: \.saturatedFatUnit, unit: "g") &&
    nutriments.equals(keyPath: \.transFatUnit, unit: "g") &&
    nutriments.equals(keyPath: \.monounsaturatedFatUnit, unit: "g") &&
    nutriments.equals(keyPath: \.polyunsaturatedFatUnit, unit: "g") &&
    nutriments.equals(keyPath: \.fiberUnit, unit: "g") &&
    nutriments.equals(keyPath: \.sugarsUnit, unit: "g") &&
    (nutriments.equals(keyPath: \.cholesterolUnit, unit: "mg") || nutriments.equals(keyPath: \.cholesterolUnit, unit: "g")) &&
    (nutriments.equals(keyPath: \.sodiumUnit, unit: "mg") || nutriments.equals(keyPath: \.sodiumUnit, unit: "g")) &&
    (nutriments.equals(keyPath: \.calciumUnit, unit: "mg") || nutriments.equals(keyPath: \.calciumUnit, unit: "g")) &&
    (nutriments.equals(keyPath: \.ironUnit, unit: "mg") || nutriments.equals(keyPath: \.ironUnit, unit: "g")) &&
    (nutriments.equals(keyPath: \.potassiumUnit, unit: "mg") || nutriments.equals(keyPath: \.potassiumUnit, unit: "g")) &&
    (nutriments.equals(keyPath: \.magnesiumUnit, unit: "mg") || nutriments.equals(keyPath: \.magnesiumUnit, unit: "g")) &&
    (nutriments.equals(keyPath: \.zincUnit, unit: "mg") || nutriments.equals(keyPath: \.zincUnit, unit: "g")) &&
    (nutriments.equals(keyPath: \.vitaminAUnit, unit: "µg") || nutriments.equals(keyPath: \.vitaminAUnit, unit: "mg") || nutriments.equals(keyPath: \.vitaminAUnit, unit: "IU") || nutriments.equals(keyPath: \.vitaminAUnit, unit: "g")) &&
    nutriments.equals(keyPath: \.vitaminB6Unit, unit: "mg") &&
    (nutriments.equals(keyPath: \.vitaminB12Unit, unit: "g") || nutriments.equals(keyPath: \.vitaminB12Unit, unit: "mg") || nutriments.equals(keyPath: \.vitaminB12Unit, unit: "µg")) &&
    (nutriments.equals(keyPath: \.vitaminCUnit, unit: "mg") || nutriments.equals(keyPath: \.vitaminCUnit, unit: "g") || nutriments.equals(keyPath: \.vitaminCUnit, unit: "IU") || nutriments.equals(keyPath: \.vitaminCUnit, unit: "µg")) &&
    (nutriments.equals(keyPath: \.vitaminDUnit, unit: "mg") || nutriments.equals(keyPath: \.vitaminDUnit, unit: "g") || nutriments.equals(keyPath: \.vitaminDUnit, unit: "IU") || nutriments.equals(keyPath: \.vitaminDUnit, unit: "µg")) &&
    (nutriments.equals(keyPath: \.vitaminEUnit, unit: "mg") || nutriments.equals(keyPath: \.vitaminEUnit, unit: "g") || nutriments.equals(keyPath: \.vitaminEUnit, unit: "IU") || nutriments.equals(keyPath: \.vitaminEUnit, unit: "µg"))
  }

  var sanitizedCountries: [String] {
    countriesTags.map({ $0.replacingOccurrences(of: "en:", with: "").lowercased() })
  }
}
