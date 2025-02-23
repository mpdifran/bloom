//
//  FoodController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation
import Vapor
import BloomModel

// MARK: - FoodController

struct FoodController {
  private let edamamService = EdamamFoodService()
  private let openAIService = OpenAIService()
  private let foodDatabaseService = FoodDatabaseService()
  private let openFoodFactsService = OpenFoodFactsService()
}

// MARK: - RouteCollection

extension FoodController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.auth(using: UserToken.self) {
        $0.group("food") {
          $0.post("autocomplete", use: autocomplete)
          $0.post("estimate", use: estimateFoodCalories)
          $0.post("search", use: searchFoods)
          $0.post("upload", use: uploadNewFood)
          $0.post("mark-as-inaccurate", use: markAsInaccurate)
          $0.post("submit-food-item-issue", use: submitFoodItemIssue)
        }
      }
    }
  }
}

// MARK: - Route Handlers

extension FoodController {

  @Sendable
  func autocomplete(_ request: Request) async throws -> FoodAutocompleteResponse {
//    let requestBody = try request.content.decode(FoodAutocompleteRequest.self)
//    let tokens = try await edamamService.autocomplete(
//      request: request,
//      query: requestBody.query
//    )

    return FoodAutocompleteResponse(tokens: [])
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

    // Both country and barcode need to match for it to be considered the same.
    if let foodItem = existingFoodItems.first(where: { $0.country?.asCountry() == requestBody.country.country }) {
      do {
        // Try updating images if they're missing.
        try await foodDatabaseService.addProductImagesIfMissing(
          request,
          foodID: foodItem.id,
          nutritionImage: requestBody.nutritionLabelImage,
          packagingImage: requestBody.packagingImage
        )
      } catch {
        request.logger.error(error)
      }

      return UploadNewFoodResponse(
        result: .foodLogged,
        foodItem: foodItem
      )
    }

    let nutritionLabelMetadata = try await request.imageStorage.store(
      image: requestBody.nutritionLabelImage,
      path: .nutritionLabel
    )
    let packagingMetadata = try await request.imageStorage.store(
      image: requestBody.packagingImage,
      path: .foodPackaging
    )

    do {
      let (foodItemRecord, result) = try await openAIService.parseNewFoodItem(
        request: request,
        barCode: requestBody.barcode,
        country: requestBody.country.country,
        nutritionLabelMetadata: nutritionLabelMetadata,
        packagingMetadata: packagingMetadata
      )

      try await foodItemRecord?.save(on: request.db)

      let foodItem = foodItemRecord?.asFoodItem()

      return UploadNewFoodResponse(
        result: result,
        foodItem: foodItem
      )
    } catch {
      // TODO: Delete nutritionLabelMetadata and packagingMetadata from S3.

      throw error
    }
  }

  @Sendable
  func estimateFoodCalories(_ request: Request) async throws -> EstimateFoodCaloriesResponse {
    let requestBody = try request.content.decode(EstimateFoodCaloriesRequest.self)

    guard let foodEstimate = await openAIService.estimateCalories(
      request,
      foodImageFile: requestBody.foodImage
    ) else {
      throw Abort(.internalServerError)
    }

    let servings = foodEstimate.items.map { $0.asServing() }
    let suggestedServings = foodEstimate.optionalItems.map { $0.asServing() }

    return EstimateFoodCaloriesResponse(
      name: foodEstimate.name,
      servings: servings,
      suggestedServings: suggestedServings
    )
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

  @Sendable
  func submitFoodItemIssue(_ request: Request) async throws -> Response {
    let requestBody = try request.content.decode(SubmitFoodItemIssueRequest.self)

    try await foodDatabaseService.submitFoodItemIssueReport(
      request,
      foodItemIssue: requestBody.foodItemIssue
    )

    return Response(status: .ok)
  }
}

// MARK: - Private Methods

private extension FoodController {

  func searchFoodsLocalDatabase(_ request: Request) async throws -> [FoodSearchResponse.Section] {
    let requestBody = try request.content.decode(FoodSearchRequest.self)

    if let barcode = requestBody.upcCode {
      do {
        let sections = await searchFoodsBarcodeLocalDatabase(request, barcode: barcode)
        if sections.isNotEmpty {
          return sections
        } else {
          let foodItems = try await openFoodFactsService.insertProduct(request, barcode: barcode)
          return [
            FoodSearchResponse.Section(
              title: "Matched Barcode",
              index: 0,
              category: .branded,
              foods: foodItems
            )
          ]
        }
      } catch {
        request.logger.error(error)
      }
    } else if let name = requestBody.name {
      return await searchFoodsByNameLocalDatabase(
        request,
        name: name,
        country: requestBody.country?.country ?? .usa
      )
    } else {
      throw Abort(.badRequest)
    }

    return []
  }

  func searchFoodsBarcodeLocalDatabase(_ request: Request, barcode: String) async -> [FoodSearchResponse.Section] {
    do {
      let foodItems = try await foodDatabaseService.searchFoods(
        request: request,
        barcode: barcode
      )

      guard foodItems.isNotEmpty else { return [] }

      let section = FoodSearchResponse.Section(
        title: "Matched Barcode",
        index: 0,
        category: .branded,
        foods: foodItems
      )

      return [section]
    } catch {
      request.logger.error(error)
    }
    return []
  }

  func searchFoodsByNameLocalDatabase(
    _ request: Request,
    name: String,
    country: FoodItemRecord.Country
  ) async -> [FoodSearchResponse.Section] {
    do {
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
            category: .branded,
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
            category: .restaurant,
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
            category: .fastfood,
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
            category: .generic,
            foods: foodItems
          )
        }

        for try await section in group {
          guard let section else { continue }

          sections.append(section)
        }
      }

      return sections.sorted(by: { $0.index < $1.index })
    } catch {
      request.logger.error(error)
    }

    return []
  }
}
