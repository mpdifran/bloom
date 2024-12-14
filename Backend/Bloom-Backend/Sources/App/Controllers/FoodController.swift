//
//  FoodController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation
import Vapor
import BloomModel

struct FoodController {
  private let edamamService = EdamamFoodService()
  private let openAIService = OpenAIService()
  private let foodDatabaseService = FoodDatabaseService()
  private let openFoodFactsService = OpenFoodFactsService()
}

extension FoodController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1", "food") { food in
      food.post("autocomplete", use: autocomplete)
      food.post("estimate", use: estimateFoodCalories)
      food.post("search", use: searchFoods)
      food.post("upload", use: uploadNewFood)
      food.post("mark-as-inaccurate", use: markAsInaccurate)
    }
  }
}

extension FoodController {

  @Sendable
  func autocomplete(_ request: Request) async throws -> FoodAutocompleteResponse {
    let requestBody = try request.content.decode(FoodAutocompleteRequest.self)

    let tokens = try await edamamService.autocomplete(
      request: request,
      query: requestBody.query
    )

    return FoodAutocompleteResponse(tokens: tokens)
  }

  @Sendable
  func searchFoods(_ request: Request) async throws -> FoodSearchResponse {
    let sections = try await searchFoodsLocalDatabase(request)
    return FoodSearchResponse(sections: sections)
  }

  @Sendable
  func uploadNewFood(_ request: Request) async throws -> UploadNewFoodResponse {
    let requestBody = try request.content.decode(UploadNewFoodRequest.self)

    let existingFoodItems = try await foodDatabaseService.searchFoods(
      request: request,
      barcode: requestBody.barcode
    )

    if let foodItem = existingFoodItems.first {
      return UploadNewFoodResponse(
        result: .foodLogged,
        foodItem: foodItem
      )
    }

    let nutritionLabelMetadata = try await save(image: requestBody.nutritionLabelImage, request: request, path: .nutritionLabel)
    let packagingMetadata = try await save(image: requestBody.packagingImage, request: request, path: .foodPackaging)

    let (foodItemRecord, result) = try await openAIService.parseNewFoodItem(
      request: request,
      barCode: requestBody.barcode,
      country: requestBody.country,
      nutritionLabelMetadata: nutritionLabelMetadata,
      packagingMetadata: packagingMetadata
    )

    try await foodItemRecord?.save(on: request.db)

    let foodItem = foodItemRecord?.asFoodItem()

    return UploadNewFoodResponse(
      result: result,
      foodItem: foodItem
    )
  }

  @Sendable
  func estimateFoodCalories(_ request: Request) async throws -> EstimateFoodCaloriesResponse {
    let requestBody = try request.content.decode(EstimateFoodCaloriesRequest.self)

    let foodEstimate = await openAIService.estimateCalories(request: request, foodImageFile: requestBody.foodImage)

    let servings = foodEstimate?.items.map({ item in item.asServing() }) ?? []

    return EstimateFoodCaloriesResponse(servings: servings)
  }

  @Sendable
  func markAsInaccurate(_ request: Request) async throws -> Response {
    let requestBody = try request.content.decode(MarkFoodInaccurateRequest.self)

    try await foodDatabaseService.markFoodAsInaccurate(
      request: request,
      foodID: requestBody.foodId
    )

    return Response(status: .ok)
  }
}

private extension FoodController {

  func searchFoodsLocalDatabase(_ request: Request) async throws -> [FoodSearchResponse.Section] {
    let requestBody = try request.content.decode(FoodSearchRequest.self)

    if let barcode = requestBody.upcCode {
      let sections = try await searchFoodsBarcodeLocalDatabase(request, barcode: barcode)
      if sections.isNotEmpty {
        return sections
      } else {
        return try await searchFoodsBarcodeOpenFoodFacts(request, barcode: barcode)
      }
    } else if let name = requestBody.name {
      return try await searchFoodsByNameLocalDatabase(
        request,
        name: name,
        country: requestBody.country?.country ?? .usa
      )
    } else {
      throw Abort(.badRequest)
    }
  }

  func searchFoodsBarcodeLocalDatabase(_ request: Request, barcode: String) async throws -> [FoodSearchResponse.Section] {
    let foodItems = try await foodDatabaseService.searchFoods(
      request: request,
      barcode: barcode
    )

    guard foodItems.isNotEmpty else { return [] }

    let section = FoodSearchResponse.Section(
      title: "Matched Barcode",
      index: 0,
      foods: foodItems
    )

    return [section]
  }

  func searchFoodsBarcodeOpenFoodFacts(_ request: Request, barcode: String) async throws -> [FoodSearchResponse.Section] {
    let response = try await openFoodFactsService.fetchProductImages(request, barcode: barcode)

    guard let images = response.product.selectedImages else {
      request.logger.info("Open Food Facts product had no images.")
      return []
    }

    guard
      let packageURI = images.front?.display?.en?.uri ?? images.front?.display?.fr?.uri, // Fallback to french if there's no English
      let nutritionLabelURI = images.nutrition?.display?.en?.uri ?? images.nutrition?.display?.fr?.uri, // Fallback to french if there's no English
      let packaging = try await request.client.get(packageURI).body,
      let nutritionLabel = try await request.client.get(nutritionLabelURI).body
    else {
      request.logger.info("Could not load images from Open Food Facts Product.")
      return []
    }

    guard let countries = response.product.countries else {
      request.logger.info("Could not load countries from Open Food Facts Product.")
      return[]
    }

    let packagingData = Data(packaging.readableBytesView)
    let nutritionLabelData = Data(nutritionLabel.readableBytesView)

    let packagingMetadata = try await save(
      image: .init(data: packagingData, fileExtension: "png") ,
      request: request,
      path: .foodPackaging
    )
    let nutritionLabelMetadata = try await save(
      image: .init(data: nutritionLabelData, fileExtension: "png"),
      request: request,
      path: .nutritionLabel
    )

    let country: FoodCountry
    if countries.contains("Canada") {
      country = .canada
    } else if countries.contains("United States") {
      country = .usa
    } else {
      request.logger.info("[OpenFoodFacts] Unsupported country code: \(countries).")
      return []
    }

    let aiResponse = try await openAIService.parseNewFoodItem(
      request: request,
      barCode: barcode,
      country: country,
      nutritionLabelMetadata: nutritionLabelMetadata,
      packagingMetadata: packagingMetadata
    )

    guard let foodItemRecord = aiResponse.0 else { return [] }

    foodItemRecord.source = "Open Food Facts"
    foodItemRecord.ingredients = response.product.ingredients

    guard let foodItem = foodItemRecord.asFoodItem() else { return [] }

    try await foodItemRecord.save(on: request.db)

    let section = FoodSearchResponse.Section(
      title: "Matched Barcode",
      index: 0,
      foods: [foodItem]
    )

    return [section]
  }

  func searchFoodsByNameLocalDatabase(
    _ request: Request,
    name: String,
    country: FoodItemRecord.Country
  ) async throws -> [FoodSearchResponse.Section] {
    var sections = [FoodSearchResponse.Section]()

    try await withThrowingTaskGroup(of: FoodSearchResponse.Section?.self) { group in
      group.addTask {
        let foodItems = try await foodDatabaseService.searchFoods(
          request: request,
          query: name,
          category: .branded,
          preferredCountry: country,
          limit: 20
        )
        guard foodItems.isNotEmpty else { return nil }

        return FoodSearchResponse.Section(
          title: "Branded",
          index: 0,
          foods: foodItems
        )
      }
      group.addTask {
        let foodItems = try await foodDatabaseService.searchFoods(
          request: request,
          query: name,
          category: .restaurant,
          preferredCountry: country,
          limit: 20
        )
        guard foodItems.isNotEmpty else { return nil }

        return FoodSearchResponse.Section(
          title: "Restaurant",
          index: 1,
          foods: foodItems
        )
      }
      group.addTask {
        let foodItems = try await foodDatabaseService.searchFoods(
          request: request,
          query: name,
          category: .fastfood,
          preferredCountry: country,
          limit: 20
        )
        guard foodItems.isNotEmpty else { return nil }

        return FoodSearchResponse.Section(
          title: "Fast Food",
          index: 2,
          foods: foodItems
        )
      }
      group.addTask {
        let foodItems = try await foodDatabaseService.searchFoods(
          request: request,
          query: name,
          category: .generic,
          preferredCountry: country,
          limit: 20
        )
        guard foodItems.isNotEmpty else { return nil }

        return FoodSearchResponse.Section(
          title: "Generic",
          index: 3,
          foods: foodItems
        )
      }

      for try await section in group {
        guard let section else { continue }

        sections.append(section)
      }
    }

    return sections.sorted(by: { $0.index < $1.index })
  }

  func searchFoodsEdamam(_ request: Request) async throws -> FoodSearchResponse.Section? {
    let requestBody = try request.content.decode(FoodSearchRequest.self)

    let otherFoodItems: [FoodItem]
    if let upcCode = requestBody.upcCode {
      otherFoodItems = try await edamamService.searchFoods(
        request: request,
        upc: upcCode
      )
    } else if let name = requestBody.name {
      otherFoodItems = try await edamamService.searchFoods(
        request: request,
        name: name,
        brand: requestBody.brand
      )
    } else {
      throw Abort(.badRequest)
    }

    guard otherFoodItems.isNotEmpty else { return nil }

    return FoodSearchResponse.Section(
      title: "Other",
      index: 2,
      foods: otherFoodItems
    )
  }
}

private extension FoodController {

  /// Saves images using the `request.imageStorage`
  /// - Parameters:
  ///   - image: The image to save
  ///   - request: The request context for the current request.
  ///   - path: The path in which to store the image
  /// - Returns: ImageFileMetadata
  ///   The metadata for the resulting image.
  func save(image: ImageFile,
            request: Request,
            path: StoragePath) async throws -> ImageFileMetadata {
    return try await request.imageStorage.store(image: image, path: path)
  }
}
