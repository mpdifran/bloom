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


    init(app: Application) {
        self.app = app
        self.edamamController = EdamamFoodController(app: app)
    }
}

extension FoodController: RouteCollection {

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.group("v1") { v1 in
            v1.group("food") { food in
                food.post("autocomplete", use: autocomplete)
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
}
