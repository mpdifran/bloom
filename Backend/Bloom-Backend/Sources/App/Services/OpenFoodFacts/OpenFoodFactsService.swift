//
//  OpenFoodFactsService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-05.
//

import Vapor
import BloomModel

struct OpenFoodFactsService {
  let baseURL = URL(string: "https://world.openfoodfacts.net/api/v2/")!
  var defaultHeaders: HTTPHeaders = {
    var headers = HTTPHeaders()
    headers.add(name: .userAgent, value: "Bloom-Backend/1.0 (hello@trybloom.app)")
    return headers
  }()

  private let foodDatabaseService = FoodDatabaseService()
}

extension OpenFoodFactsService {

  func fetchProductImages(_ request: Request, barcode: String) async throws -> OpenFoodFactsProductResponse {
    let url = baseURL
      .appending(component: "product")
      .appending(component: barcode)
      .appending(queryItems: [
        URLQueryItem(name: "fields", value: "id,selected_images,countries_tags_en,ingredients_text_en")
      ])

    let response = try await request.client.get(URI(string: url.absoluteString), headers: defaultHeaders)

//    if let body = response.body {
//      let data = Data(buffer: body)
//      let string = String(data: data, encoding: .utf8)
//      print(string ?? "")
//    }

    return try response.content.decode(OpenFoodFactsProductResponse.self)
  }
}

extension OpenFoodFactsService {

  func bulkUpload(_ request: Request, items: [AdminOpenFoodFactsBulkUploadItem]) async throws -> Int {
    try await request.db.transaction { database in
      var count = 0

      for item in items {
        guard
          try await foodDatabaseService.searchFoods(request: request, barcode: item.barcode).isEmpty
        else {
          continue // TODO: Do we want to update in this case?
        }

        let country: FoodItemRecord.Country
        if item.countries.contains("canada") {
          country = .canada
        } else if item.countries.contains("united-states") {
          country = .usa
        } else {
          request.logger.info("Unknown country for bulk uplaoded Open Food Facts item: \(item.countries)")
          continue
        }

        let foodItemRecord = FoodItemRecord(
          id: item.barcode,
          name: item.productName ?? "",
          country: country,
          category: .branded,
          source: "Open Food Facts"
        )

        foodItemRecord.barcode = item.barcode
        foodItemRecord.brandName = item.brand
        foodItemRecord.flavour = nil

        foodItemRecord.calories = item.energy
        foodItemRecord.protein = item.protein
        foodItemRecord.carbohydrates = item.carbohydrates
        foodItemRecord.fat = item.fat
        foodItemRecord.saturatedFat = item.saturatedFat
        foodItemRecord.transFat = item.transFat
        foodItemRecord.polyunsaturatedFat = item.polyunsaturatedFat
        foodItemRecord.monounsaturatedFat = item.monounsaturatedFat
        foodItemRecord.fiber = item.fiber
        foodItemRecord.sugar = item.sugar
        foodItemRecord.cholesterol = item.cholesterol
        foodItemRecord.sodium = item.sodium
        foodItemRecord.calcium = item.calcium
        foodItemRecord.iron = item.iron
        foodItemRecord.potassium = item.potassium
        foodItemRecord.magnesium = item.magnesium
        foodItemRecord.zinc = item.zinc
        foodItemRecord.vitaminA = item.vitaminA
        foodItemRecord.vitaminB6 = item.vitaminB6
        foodItemRecord.vitaminB12 = item.vitaminB12
        foodItemRecord.vitaminC = item.vitaminC
        foodItemRecord.vitaminD = item.vitaminD
        foodItemRecord.vitaminE = item.vitaminE
        foodItemRecord.servingName = "1 Serving"
        foodItemRecord.servingValue = item.servingQuantity
        foodItemRecord.servingUnit = item.servingUnit

        foodItemRecord.packagingImage = item.packagingImageURL?.absoluteString
        foodItemRecord.nutritionLabelImage = item.nutrientsImageURL?.absoluteString

        foodItemRecord.ingredients = item.ingredients

        foodItemRecord.state = .unverified

        try await foodItemRecord.save(on: database)
        count += 1
      }

      return count
    }
  }
}
