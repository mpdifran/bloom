//
//  OpenFoodFactsProduct.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-05.
//

import Foundation

struct OpenFoodFactsProduct: Codable {
  let id: String
  let productName: String?
  let brandOwner: String?
  let brands: String?
  let nutriments: Nutriments
  let ingredients: String?
  let servingSize: String?
  let servingQuantity: Double?
  let servingQuantityUnit: String?
  let selectedImages: SelectedImages?
  let countries: [String]?

  enum CodingKeys: String, CodingKey {
    case id = "id"
    case productName = "productNameEn"
    case brandOwner
    case brands
    case nutriments
    case ingredients = "ingredientsTextEn"
    case servingSize
    case servingQuantity
    case servingQuantityUnit
    case selectedImages = "selectedImages"
    case countries = "countriesTags"
  }

  init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.id = try container.decode(String.self, forKey: .id)
    self.productName = try container.decodeIfPresent(String.self, forKey: .productName)
    self.brandOwner = try container.decodeIfPresent(String.self, forKey: .brandOwner)
    self.brands = try container.decodeIfPresent(String.self, forKey: .brands)
    self.nutriments = try container.decode(OpenFoodFactsProduct.Nutriments.self, forKey: .nutriments)
    self.ingredients = try container.decodeIfPresent(String.self, forKey: .ingredients)
    self.servingSize = try container.decodeIfPresent(String.self, forKey: .servingSize)

    if let doubleQuantity = try? container.decodeIfPresent(Double.self, forKey: .servingQuantity) {
      self.servingQuantity = doubleQuantity
    } else if let stringQuantity = try? container.decodeIfPresent(String.self, forKey: .servingQuantity) {
      self.servingQuantity = Double(stringQuantity)
    } else {
      self.servingQuantity = nil
    }
    self.servingQuantityUnit = try container.decodeIfPresent(String.self, forKey: .servingQuantityUnit)
    self.selectedImages = try container.decodeIfPresent(OpenFoodFactsProduct.SelectedImages.self, forKey: .selectedImages)
    self.countries = try container.decodeIfPresent([String].self, forKey: .countries)
  }
}

extension OpenFoodFactsProduct {
  struct Nutriments: Codable {
    let energyServing: Double?
    let proteinsServing: Double?
    let carbohydratesServing: Double?
    let fatServing: Double?
    let saturatedFatServing: Double?
    let transFatServing: Double?
    let polyunsaturatedFatServing: Double?
    let monounsaturatedFatServing: Double?
    let fiberServing: Double?
    let sugarsServing: Double?
    let cholesterolServing: Double?
    let sodiumServing: Double?
    let calciumServing: Double?
    let ironServing: Double?
    let potassiumServing: Double?
    let magnesiumServing: Double?
    let zincServing: Double?
    let vitaminAServing: Double?
    let vitaminB6Serving: Double?
    let vitaminB12Serving: Double?
    let vitaminCServing: Double?
    let vitaminDServing: Double?
    let vitaminEServing: Double?

    enum CodingKeys: String, CodingKey {
      case energyServing = "energy-kcalServing"
      case proteinsServing
      case carbohydratesServing
      case fatServing
      case saturatedFatServing = "saturated-fatServing"
      case transFatServing = "trans-fatServing"
      case polyunsaturatedFatServing = "polyunsaturated-fatServing"
      case monounsaturatedFatServing = "monounsaturated-fatServing"
      case fiberServing
      case sugarsServing
      case cholesterolServing
      case sodiumServing
      case calciumServing
      case ironServing
      case potassiumServing
      case magnesiumServing
      case zincServing
      case vitaminAServing = "vitamin-aServing"
      case vitaminB6Serving = "vitamin-b6Serving"
      case vitaminB12Serving = "vitamin-b12Serving"
      case vitaminCServing = "vitamin-cServing"
      case vitaminDServing = "vitamin-dServing"
      case vitaminEServing = "vitamin-eServing"
    }
  }

  struct SelectedImages: Codable {
    let front: ImageSet?
    let ingredients: ImageSet?
    let nutrition: ImageSet?
    let packaging: ImageSet?
  }
}

extension OpenFoodFactsProduct.SelectedImages {
  struct ImageSet: Codable {
    let display: LocalizedImages?
    let small: LocalizedImages?
    let thumb: LocalizedImages?
  }
  struct LocalizedImages: Codable {
    let en: URL?
    let fr: URL?
  }
}

extension OpenFoodFactsProduct.SelectedImages.ImageSet {

  var bestAvailableImage: URL? {
    if let english = display?.en ?? small?.en ?? thumb?.en {
      return english
    }
    return display?.fr ?? small?.fr ?? thumb?.fr
  }
}

extension OpenFoodFactsProduct {

  var standardizedCountries: [String] {
    let lowercasedCountries = countries?
      .map({ $0.lowercased() })
      .map({ $0.replacingOccurrences(of: "en:", with: "") }) ?? []

    return lowercasedCountries.compactMap({ countryCode in
      if ["united-states", "united states", "usa"].contains(countryCode) {
        return "usa"
      } else if ["canada"].contains(countryCode) {
        return "canada"
      } else if !countryCode.isEmpty {
        // For any other country, normalize the name and return it
        return countryCode.replacingOccurrences(of: "-", with: " ")
      }
      return nil
    })
  }
}
