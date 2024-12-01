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
}

extension FoodController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        routes.group("v1", "food") { food in
            food.post("autocomplete", use: autocomplete)
            food.post("estimate", use: estimateFoodCalories)
            food.post("search", use: searchFoods)
            food.post("upload", use: uploadNewFood)
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
}

private extension FoodController {

    func searchFoodsLocalDatabase(_ request: Request) async throws -> [FoodSearchResponse.Section] {
        let requestBody = try request.content.decode(FoodSearchRequest.self)

        if let barcode = requestBody.upcCode {
            return try await searchFoodsBarcodeLocalDatabase(request, barcode: barcode)
        } else if let name = requestBody.name {
            return try await searchFoodsByNameLocalDatabase(request, name: name)
        } else {
            throw Abort(.badRequest)
        }
    }

    func searchFoodsBarcodeLocalDatabase(_ request: Request, barcode: String) async throws -> [FoodSearchResponse.Section] {
        let foodItems = try await foodDatabaseService.searchFoods(
            request: request,
            barcode: barcode
        )

        let section = FoodSearchResponse.Section(
            title: "Matched Barcode",
            index: 0,
            foods: foodItems
        )

        return [section]
    }

    func searchFoodsByNameLocalDatabase(_ request: Request, name: String) async throws -> [FoodSearchResponse.Section] {
        var sections = [FoodSearchResponse.Section]()

        try await withThrowingTaskGroup(of: FoodSearchResponse.Section?.self) { group in
            group.addTask {
                let foodItems = try await foodDatabaseService.searchFoods(
                    request: request,
                    query: name,
                    category: .branded,
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
