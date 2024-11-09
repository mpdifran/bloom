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

    let app: Application

    init(app: Application) {
        self.app = app
    }
}

extension FoodController: RouteCollection {

    func boot(routes: any Vapor.RoutesBuilder) throws {
        routes.group("v1") { v1 in
            v1.group("food") { food in
                food.get("autocomplete", use: autocomplete)
            }
        }
    }
}

extension FoodController {

    @Sendable
    func autocomplete(_ request: Request) async throws -> FoodAutocompleteResponse {
        throw NSError(domain: "Not implemented", code: 501)
    }
}
