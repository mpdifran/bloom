//
//  OpenFoodFactsFoodItem.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-12-04.
//

import Foundation

struct OpenFoodFactsFoodItem: Codable {
  let id: String?
  let code: String?
  let countriesTags: [String]
  let ingredientsTextEn: String?
}

//extension OpenFoodFactsFoodItem {
//  struct Nutriments: Codable {
//    let energyValue: Double?
//    let energyUnit: String?
//    let proteinsValue: Double?
//    let proteinsUnit: String?
//    let carbohydratesValue: Double?
//    let carbohydratesUnit: String?
//    let fatValue: Double?
//    let fatUnit: String?
//    let saturatedFatValue: Double?
//    let saturatedFatUnit: String?
//    let sodiumValue: Double?
//    let sodiumUnit: String?
//    let sugarsValue: Double?
//    let sugarsUnit: String?
//  }
//
//  struct SelectedImages: Codable {
//    let front: ImageSet
//    let ingredients: ImageSet
//    let nutrition: ImageSet
//    let packaging: ImageSet
//  }
//}
//
//extension OpenFoodFactsFoodItem.SelectedImages {
//  struct ImageSet: Codable {
//    let display: LocalizedImages
//    let small: LocalizedImages
//    let thumb: LocalizedImages
//  }
//  struct LocalizedImages: Codable {
//    let en: URL
//  }
//}
