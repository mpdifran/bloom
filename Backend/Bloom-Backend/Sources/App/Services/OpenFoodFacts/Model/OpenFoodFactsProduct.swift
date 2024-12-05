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
  let brands: String?
  let nutriments: Nutriments
  let ingredients: String?
  let quantity: String?
  let selectedImages: SelectedImages?
  let countries: String?

  enum CodingKeys: String, CodingKey {
    case id = "id"
    case productName = "product_name_en"
    case brands
    case nutriments
    case ingredients = "ingredients_text_en"
    case quantity
    case selectedImages = "selected_images"
    case countries = "countries_lc"
  }
}

extension OpenFoodFactsProduct {
  struct Nutriments: Codable {
    let energyValue: Double?
    let energyUnit: String?
    let proteinsValue: Double?
    let proteinsUnit: String?
    let carbohydratesValue: Double?
    let carbohydratesUnit: String?
    let fatValue: Double?
    let fatUnit: String?
    let saturatedFatValue: Double?
    let saturatedFatUnit: String?
    let sodiumValue: Double?
    let sodiumUnit: String?
    let sugarsValue: Double?
    let sugarsUnit: String?
  }

  struct SelectedImages: Codable {
    let front: ImageSet
    let ingredients: ImageSet
    let nutrition: ImageSet
    let packaging: ImageSet
  }
}

extension OpenFoodFactsProduct.SelectedImages {
  struct ImageSet: Codable {
    let display: LocalizedImages
    let small: LocalizedImages
    let thumb: LocalizedImages
  }
  struct LocalizedImages: Codable {
    let en: URL
  }
}
