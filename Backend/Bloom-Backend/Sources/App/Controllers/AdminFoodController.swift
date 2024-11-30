//
//  AdminFoodController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-15.
//

import Foundation
import BloomModel
import Vapor
import Fluent

struct AdminFoodController {
  private let foodDatabaseService = FoodDatabaseService()
}

extension AdminFoodController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        routes.group("v1", "admin", "food") { food in
            food.post("usda-ingest", use: ingestUSDA)
            food.get("unverified", use: getUnverifiedFoods)
        }
    }
}

private extension AdminFoodController {

    @Sendable
    func ingestUSDA(_ request: Request) async throws -> USDAImportFoodResponse {
        let requestBody = try request.content.decode(USDAImportFoodRequest.self)

        let category: FoodItemRecord.Category
        switch requestBody.kind {
        case .foundation:
            category = .generic
        }

        var count = 0
        for foodItem in requestBody.foods {
            guard
                let foodItemRecord = try await foodItem.asFoodItemRecord(
                    request: request,
                    category: category
                )
            else { continue }

            try await foodItemRecord.createOrUpdate(on: request.db)
            count += 1
        }

        return USDAImportFoodResponse(addedFoodItemsCount: count)
    }

  @Sendable
  func getUnverifiedFoods(_ request: Request) async throws -> UnverifiedFoodItemsResponse {
    let query = try request.query.decode(UnverifiedQuery.self)
    let limit = query.limit ?? 100 // Default to 100 if not provided.

    let foodItems = try await foodDatabaseService.getUnverifiedFoods(
      request: request,
      limit: limit
    )

    return UnverifiedFoodItemsResponse(foodItems: foodItems)
  }
}
