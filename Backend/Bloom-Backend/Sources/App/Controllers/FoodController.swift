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

    private let app: Application
    private let edamamController: EdamamFoodController
    private let usdaFoodController: USDAFoodController


    init(app: Application) {
        self.app = app
        self.edamamController = EdamamFoodController(app: app)
        self.usdaFoodController = USDAFoodController(app: app)
    }
}

extension FoodController: RouteCollection {

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.group("v1") { v1 in
            v1.group("food") { food in
                food.post("autocomplete", use: autocomplete)
                food.post("search", use: searchFoods)
            }
        }
    }
}

extension FoodController {

    @Sendable
    func autocomplete(_ request: Request) async throws -> FoodAutocompleteResponse {
        let requestBody = try request.content.decode(FoodAutocompleteRequest.self)

        let tokens = try await edamamController.autocomplete(
            client: request.client,
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
                return try await searchFoodUSDA(request)
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
}

private extension FoodController {

    func searchFoodUSDA(_ request: Request) async throws -> FoodSearchResponse.Section? {
        let requestBody = try request.content.decode(FoodSearchRequest.self)

        guard let name = requestBody.name else { return nil }

        let foodItems = try await usdaFoodController.foundationFoodSearch(
            client: request.client,
            query: name
        )

        guard foodItems.isNotEmpty else { return nil }

        return FoodSearchResponse.Section(
            title: "Foundation",
            index: 1,
            foods: foodItems
        )
    }

    func searchFoodsEdamam(_ request: Request) async throws -> FoodSearchResponse.Section? {
        let requestBody = try request.content.decode(FoodSearchRequest.self)

        let otherFoodItems: [FoodItem]
        if let upcCode = requestBody.upcCode {
            otherFoodItems = try await edamamController.searchFoods(
                client: request.client,
                upc: upcCode
            )
        } else if let name = requestBody.name {
            otherFoodItems = try await edamamController.searchFoods(
                client: request.client,
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
