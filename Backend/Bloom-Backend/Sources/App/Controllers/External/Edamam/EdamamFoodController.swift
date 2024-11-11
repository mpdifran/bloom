//
//  EdamamFoodController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation
import Vapor
import BloomModel

struct EdamamFoodController {
    let app: Application

    init(app: Application) {
        self.app = app
    }
}

extension EdamamFoodController {

    func autocomplete(
        client: Client,
        query: String
    ) async throws -> [String] {

        var urlComponents = URLComponents(string: app.edamamDomain + "/auto-complete")
        urlComponents?.queryItems = [
            URLQueryItem(name: "app_id", value: app.edamamAppID),
            URLQueryItem(name: "app_key", value: app.edamamAPIKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "6")
        ]

        guard let uri = urlComponents?.url else { throw Abort(.internalServerError) }

        let response = try await client.get(
            URI(string: uri.absoluteString),
            headers: .init(
                [("Accept-Encoding", "gzip")]
            )
        )
        return try response.content.decode([String].self)
    }

    func searchFoods(
        client: Client,
        name: String,
        brand: String?
    ) async throws -> [FoodItem] {

        var urlComponents = URLComponents(string: app.edamamDomain + "/api/food-database/v2/parser")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "app_id", value: app.edamamAppID),
            URLQueryItem(name: "app_key", value: app.edamamAPIKey),
            URLQueryItem(name: "ingr", value: name),
        ]
        if let brand {
            queryItems.append(URLQueryItem(name: "brand", value: brand))
        }
        urlComponents?.queryItems = queryItems

        guard let uri = urlComponents?.url else { throw Abort(.internalServerError) }

        let response = try await client.get(
            URI(string: uri.absoluteString),
            headers: .init(
                [("Accept-Encoding", "gzip")]
            )
        )

        let responseBody = try response.content.decode(Components.Schemas.ParseResponse.self)
        let foods = responseBody.hints?.compactMap({ $0.asFoodItem() }) ?? []

        return foods
    }

    func searchFoods(
        client: Client,
        upc: String
    ) async throws -> [FoodItem] {

        var urlComponents = URLComponents(string: app.edamamDomain + "/api/food-database/v2/parser")
        urlComponents?.queryItems = [
            URLQueryItem(name: "app_id", value: app.edamamAppID),
            URLQueryItem(name: "app_key", value: app.edamamAPIKey),
            URLQueryItem(name: "upc", value: upc),
        ]

        guard let uri = urlComponents?.url else { throw Abort(.internalServerError) }

        let response = try await client.get(
            URI(string: uri.absoluteString),
            headers: .init(
                [("Accept-Encoding", "gzip")]
            )
        )

        let responseBody = try response.content.decode(Components.Schemas.ParseResponse.self)
        let foods = responseBody.hints?.compactMap({ $0.asFoodItem() }) ?? []

        return foods
    }
}
