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
  private let openAIService = OpenAIService()
}

extension OpenFoodFactsService {

  func insertProduct(_ request: Request, barcode: String) async throws -> [FoodItem] {
    let productResponse = try await fetchProduct(request, barcode: barcode)
    let product = productResponse.product

    guard product.standardizedCountries.isNotEmpty else {
      request.logger.info("Unknown OFF countries: \(product.countries ?? [])")
      return []
    }

    guard
      let energyKCal = product.nutriments.energyServing,
      let productName = product.productName
    else {
      return try await parseImagesWithAI(request, barcode: barcode, product: product)
    }

    var foodItems = [FoodItem]()
    for country in product.standardizedCountries {
      let foodItemRecord = FoodItemRecord(
        id: UUID().uuidString,
        name: productName,
        country: country,
        category: .branded,
        source: "Open Food Facts"
      )

      foodItemRecord.brandName = product.brands ?? product.brandOwner
      foodItemRecord.flavour = nil // No field for flavour in OFF
      foodItemRecord.barcode = barcode
      foodItemRecord.nutritionLabelImage = product.selectedImages?.nutrition?.bestAvailableImage?.absoluteString
      foodItemRecord.packagingImage = product.selectedImages?.front?.bestAvailableImage?.absoluteString
      foodItemRecord.calories = energyKCal
      foodItemRecord.protein = product.nutriments.proteinsServing
      foodItemRecord.carbohydrates = product.nutriments.carbohydratesServing
      foodItemRecord.fat = product.nutriments.fatServing
      foodItemRecord.saturatedFat = product.nutriments.saturatedFatServing
      foodItemRecord.transFat = product.nutriments.transFatServing
      foodItemRecord.polyunsaturatedFat = product.nutriments.polyunsaturatedFatServing
      foodItemRecord.monounsaturatedFat = product.nutriments.monounsaturatedFatServing
      foodItemRecord.fiber = product.nutriments.fiberServing
      foodItemRecord.sugar = product.nutriments.sugarsServing
      foodItemRecord.cholesterol = product.nutriments.cholesterolServing?.mg
      foodItemRecord.sodium = product.nutriments.sodiumServing?.mg
      foodItemRecord.calcium = product.nutriments.calciumServing?.mg
      foodItemRecord.iron = product.nutriments.ironServing?.mg
      foodItemRecord.potassium = product.nutriments.potassiumServing?.mg
      foodItemRecord.magnesium = product.nutriments.magnesiumServing?.mg
      foodItemRecord.zinc = product.nutriments.zincServing?.mg
      foodItemRecord.vitaminA = product.nutriments.vitaminAServing?.mg
      foodItemRecord.vitaminB6 = product.nutriments.vitaminB6Serving?.mg
      foodItemRecord.vitaminB12 = product.nutriments.vitaminB12Serving?.mg
      foodItemRecord.vitaminC = product.nutriments.vitaminCServing?.mg
      foodItemRecord.vitaminD = product.nutriments.vitaminDServing?.mg
      foodItemRecord.vitaminE = product.nutriments.vitaminEServing?.mg
      foodItemRecord.servingName = product.servingSize
      foodItemRecord.servingValue = product.servingQuantity
      foodItemRecord.servingUnit = product.servingQuantityUnit ?? "g" // Assume grams if no unit is present??
      foodItemRecord.ingredients = product.ingredients

      try await foodItemRecord.save(on: request.db)

      if let item = foodItemRecord.asFoodItem() {
        foodItems.append(item)
      }
    }

    return foodItems
  }
}

private extension OpenFoodFactsService {

  func fetchProduct(
    _ request: Request,
    barcode: String
  ) async throws -> OpenFoodFactsProductResponse {
    let url = baseURL
      .appending(component: "product")
      .appending(component: barcode)
      .appending(
        queryItems: [
          URLQueryItem(
            name: "fields",
            value: "id,product_name_en,brands,nutriments,ingredients_text_en,serving_size,serving_quantity,serving_quantity_unit,selected_images,countries_tags"
          )
        ]
      )

    let response = try await request.client.get(
      URI(string: url.absoluteString),
      headers: defaultHeaders
    )

    if let body = response.body {
      let data = Data(buffer: body)
      let string = String(data: data, encoding: .utf8)
      print(string ?? "")
    }

    return try response.content.decode(
      OpenFoodFactsProductResponse.self,
      using: JSONDecoder.openFoodFacts
    )
  }

  func parseImagesWithAI(
    _ request: Request,
    barcode: String,
    product: OpenFoodFactsProduct
  ) async throws -> [FoodItem] {
    guard let images = product.selectedImages else {
      return []
    }

    guard let firstCountry = product.standardizedCountries.first else {
      return []
    }

    guard
      let packageURI = images.front?.bestAvailableImage?.uri,
      let nutritionURI = images.nutrition?.bestAvailableImage?.uri,
      let packaging = try await request.client.get(packageURI).body,
      let nutritionLabel = try await request.client.get(nutritionURI).body
    else {
      return []
    }

    let packagingData = Data(packaging.readableBytesView)
    let nutritionLabelData = Data(nutritionLabel.readableBytesView)

    // Skip saving to our S3 since the image is hosted on OFF.
    let packagingMetadata = ImageFileMetadata(
      filename: "\(UUID().uuidString).png",
      data: packagingData
    )
    let nutritionMetadata = ImageFileMetadata(
      filename: "\(UUID().uuidString).png",
      data: nutritionLabelData
    )

    let aiResponse = try await openAIService.parseNewFoodItem(
      request: request,
      barCode: barcode,
      country: firstCountry,
      nutritionLabelMetadata: nutritionMetadata,
      packagingMetadata: packagingMetadata
    )

    guard let foodItemRecord = aiResponse.0 else { return [] }

    foodItemRecord.source = "Open Food Facts"
    foodItemRecord.ingredients = product.ingredients

    try await foodItemRecord.save(on: request.db)

    var foodItems = [FoodItem]()
    if let foodItem = foodItemRecord.asFoodItem() {
      foodItems.append(foodItem)
    }

    // Since this record may belong to multiple countries, we may need to duplicate it.
    let remainingCountries = product.standardizedCountries.filter({ $0 != firstCountry })
    for remainingCountry in remainingCountries {
      let duplicateFoodItemRecord = foodItemRecord.duplicate()
      duplicateFoodItemRecord.country = remainingCountry

      do {
        try await foodItemRecord.save(on: request.db)
      } catch {
        // We don't want to fail the whole method if a duplicate country fails to save.
        request.logger.report(error: error)
      }

      if let foodItem = duplicateFoodItemRecord.asFoodItem() {
        foodItems.append(foodItem)
      }
    }

    return foodItems
  }
}

extension OpenFoodFactsService {

  func bulkUpload(_ request: Request, items: [AdminOpenFoodFactsBulkUploadItem]) async throws -> Int {
    var count = 0

    for item in items {
      do {
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
        foodItemRecord.servingName = item.servingName
        foodItemRecord.servingValue = item.servingQuantity
        foodItemRecord.servingUnit = item.servingUnit

        foodItemRecord.packagingImage = item.packagingImageURL?.absoluteString
        foodItemRecord.nutritionLabelImage = item.nutrientsImageURL?.absoluteString

        foodItemRecord.ingredients = item.ingredients

        foodItemRecord.state = .unverified

        try await foodItemRecord.save(on: request.db)
        count += 1
      } catch {
        request.logger.error(error)
      }
    }

    return count
  }
}
