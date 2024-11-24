//
//  FoodController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation
import Vapor
import BloomModel
import S3Kit

struct FoodController {
    private let edamamService = EdamamFoodService()
    private let openAIService = OpenAIService()
    private let foodDatabaseService = FoodDatabaseService()
}

extension FoodController: RouteCollection {

    func boot(routes: any Vapor.RoutesBuilder) throws {
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
        var sections = [FoodSearchResponse.Section]()

        // parallelize
        try await withThrowingTaskGroup(of: FoodSearchResponse.Section?.self) { group in
            group.addTask {
                return try await searchFoodsLocalDatabase(request)
            }
            group.addTask {
                return try await searchFoodsEdamam(request)
            }

            for try await section in group {
                guard let section else { continue }

                sections.append(section)
            }
        }

        let sortedSections = sections.sorted(by: { $0.index < $1.index })
        return FoodSearchResponse(sections: sortedSections)
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

        let nutritionLabelMetadata = try await save(image: requestBody.nutritionLabelImage, request: request)
        let packagingMetadata = try await save(image: requestBody.packagingImage, request: request)

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

    func searchFoodsLocalDatabase(_ request: Request) async throws -> FoodSearchResponse.Section? {
        let requestBody = try request.content.decode(FoodSearchRequest.self)

        let foodItems: [FoodItem]
        if let barcode = requestBody.upcCode {
            foodItems = try await foodDatabaseService.searchFoods(
                request: request,
                barcode: barcode
            )
        } else if let name = requestBody.name {
            foodItems = try await foodDatabaseService.searchFoods(
                request: request,
                query: name,
                limit: 20
            )
        } else {
            throw Abort(.badRequest)
        }

        guard foodItems.isNotEmpty else { return nil }

        return FoodSearchResponse.Section(
            title: "Generic",
            index: 1,
            foods: foodItems
        )
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

    func save(image: ImageFile, request: Request) async throws -> ImageFileMetadata {
        let filename = "\(UUID().uuidString).\(image.fileExtension)"
        let filePath = request.application.directory.workingDirectory + "Private/Food/" + filename
        let buffer = request.application.allocator.buffer(data: image.data)

        // TODO: Write this to S3 instead.
        try await request.fileio.writeFile(buffer, at: filePath)

        return ImageFileMetadata(filename: filename, data: image.data)
    }
}
