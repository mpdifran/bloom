//
//  OpenFoodFactsService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-05.
//

import AdminBloomModel
import BloomModel
import Vapor
import Fluent

struct OpenFoodFactsService {
  let db: Database
  let client: Client
  let logger: Logger
  let foodDatabaseService: FoodDatabaseService
  let openAIService: OpenAIService

  init(
    db: Database,
    client: Client,
    logger: Logger,
    foodDatabaseService: FoodDatabaseService,
    openAIService: OpenAIService
  ) {
    self.db = db
    self.client = client
    self.logger = logger
    self.foodDatabaseService = foodDatabaseService
    self.openAIService = openAIService
  }

  private let baseURL = URL(string: "https://world.openfoodfacts.net/api/v2/")!
  private var defaultHeaders: HTTPHeaders = {
    var headers = HTTPHeaders()
    headers.add(name: .userAgent, value: "Bloom-Backend/1.0 (hello@trybloom.app)")
    return headers
  }()
}

extension OpenFoodFactsService {

  func insertProduct(barcode: String) async throws -> [FoodItem] {
    let productResponse = try await fetchProduct(barcode: barcode)
    let product = productResponse.product

    guard product.standardizedCountries.isNotEmpty else {
      logger.info("Unknown OFF countries: \(product.countries ?? [])")
      return []
    }

    guard
      let energyKCal = product.nutriments.energyServing,
      let productName = product.productName
    else {
      return try await parseImagesWithAI(barcode: barcode, product: product)
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

      try await foodItemRecord.save(on: db)

      if let item = foodItemRecord.asFoodItem() {
        foodItems.append(item)
      }
    }

    return foodItems
  }

  /// Search for products on OpenFoodFacts and import the best match if found.
  /// Used by magic scan to find branded products.
  func searchAndImportProduct(
    name: String,
    brand: String?
  ) async throws -> [FoodItem] {
    // Build search query with name and brand
    var searchTerms = name
    if let brand = brand, !brand.isEmpty {
      searchTerms = "\(brand) \(name)"
    }

    // Search OpenFoodFacts
    guard let searchResponse = try await searchProducts(query: searchTerms) else {
      return []
    }

    // Get the first product with complete nutrition data
    guard let bestProduct = searchResponse.products.first(where: { product in
      product.nutriments.energyServing != nil &&
      product.productName != nil &&
      !product.id.isEmpty
    }) else {
      return []
    }

    // Check if we already have this product in our database
    let barcode = bestProduct.id
    if try await foodDatabaseService.searchFoods(barcode: barcode).isNotEmpty {
      // Already in database, don't import again
      return []
    }

    // Import the product using existing insertProduct logic
    return try await insertProduct(barcode: barcode)
  }
}

private extension OpenFoodFactsService {

  func fetchProduct(
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

    let response = try await client.get(
      URI(string: url.absoluteString),
      headers: defaultHeaders
    )

    return try response.content.decode(
      OpenFoodFactsProductResponse.self,
      using: JSONDecoder.openFoodFacts
    )
  }

  func searchProducts(query: String) async throws -> OpenFoodFactsSearchResponse? {
    guard !query.isEmpty else { return nil }

    // OpenFoodFacts search API endpoint
    let searchURL = URL(string: "https://world.openfoodfacts.net/cgi/search.pl")!
      .appending(queryItems: [
        URLQueryItem(name: "search_terms", value: query),
        URLQueryItem(name: "search_simple", value: "1"),
        URLQueryItem(name: "action", value: "process"),
        URLQueryItem(name: "json", value: "1"),
        URLQueryItem(name: "page_size", value: "5"),
        URLQueryItem(
          name: "fields",
          value: "code,product_name_en,brands,nutriments,ingredients_text_en,serving_size,serving_quantity,serving_quantity_unit,selected_images,countries_tags"
        )
      ])

    let response = try await client.get(
      URI(string: searchURL.absoluteString),
      headers: defaultHeaders
    )

    return try response.content.decode(
      OpenFoodFactsSearchResponse.self,
      using: JSONDecoder.openFoodFacts
    )
  }

  func parseImagesWithAI(
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
      let packaging = try await client.get(packageURI).body,
      let nutritionLabel = try await client.get(nutritionURI).body
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
      barCode: barcode,
      country: firstCountry,
      nutritionLabelMetadata: nutritionMetadata,
      packagingMetadata: packagingMetadata
    )

    guard let foodItemRecord = aiResponse.0 else { return [] }

    foodItemRecord.source = "Open Food Facts"
    foodItemRecord.ingredients = product.ingredients

    try await foodItemRecord.save(on: db)

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
        try await foodItemRecord.save(on: db)
      } catch {
        // We don't want to fail the whole method if a duplicate country fails to save.
        logger.report(error: error)
      }

      if let foodItem = duplicateFoodItemRecord.asFoodItem() {
        foodItems.append(foodItem)
      }
    }

    return foodItems
  }
}

extension OpenFoodFactsService {

  func bulkUpload(items: [AdminOpenFoodFactsBulkUploadItem]) async throws -> Int {
    var count = 0

    for item in items {
      do {
        guard
          try await foodDatabaseService.searchFoods(barcode: item.barcode).isEmpty
        else {
          continue // TODO: Do we want to update in this case?
        }

        let country: String
        if item.countries.contains("canada") {
          country = "canada"
        } else if item.countries.contains("united-states") {
          country = "usa"
        } else {
          // For any other country, use the first country in the list (normalized to lowercase)
          guard let firstCountry = item.countries.first else {
            logger.info("No countries found for bulk uploaded Open Food Facts item")
            continue
          }
          country = firstCountry.lowercased().replacingOccurrences(of: "-", with: " ")
          logger.info("Using country '\(country)' for bulk uploaded Open Food Facts item")
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

        try await foodItemRecord.save(on: db)
        count += 1
      } catch {
        logger.error(error)
      }
    }

    return count
  }
}
