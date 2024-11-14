//
//  EdamamFoodService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation
import Vapor
import BloomModel

struct EdamamFoodService { }

extension EdamamFoodService {

    func autocomplete(
        request: Request,
        query: String
    ) async throws -> [String] {

        var urlComponents = URLComponents(string: request.application.edamamDomain + "/auto-complete")
        urlComponents?.queryItems = [
            URLQueryItem(name: "app_id", value: request.application.edamamAppID),
            URLQueryItem(name: "app_key", value: request.application.edamamAPIKey),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "6")
        ]

        guard let uri = urlComponents?.url else { throw Abort(.internalServerError) }

        let response = try await request.client.get(
            URI(string: uri.absoluteString)
//            headers: .init(
//                [("Accept-Encoding", "gzip")]
//            )
        )
        return try response.content.decode([String].self)
    }

    func searchFoods(
        request: Request,
        name: String,
        brand: String?
    ) async throws -> [FoodItem] {

        var urlComponents = URLComponents(string: request.application.edamamDomain + "/api/food-database/v2/parser")
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "app_id", value: request.application.edamamAppID),
            URLQueryItem(name: "app_key", value: request.application.edamamAPIKey),
            URLQueryItem(name: "ingr", value: name),
        ]
        if let brand {
            queryItems.append(URLQueryItem(name: "brand", value: brand))
        }
        urlComponents?.queryItems = queryItems

        guard let uri = urlComponents?.url else { throw Abort(.internalServerError) }

        let response = try await request.client.get(
            URI(string: uri.absoluteString)
//            headers: .init(
//                [("Accept-Encoding", "gzip")]
//            )
        )

        let responseBody = try response.content.decode(Components.Schemas.ParseResponse.self)
        let foods = responseBody.hints?.compactMap({ $0.asFoodItem() }) ?? []

        return foods
    }

    func searchFoods(
        request: Request,
        upc: String
    ) async throws -> [FoodItem] {

        var urlComponents = URLComponents(string: request.application.edamamDomain + "/api/food-database/v2/parser")
        urlComponents?.queryItems = [
            URLQueryItem(name: "app_id", value: request.application.edamamAppID),
            URLQueryItem(name: "app_key", value: request.application.edamamAPIKey),
            URLQueryItem(name: "upc", value: upc),
        ]

        guard let uri = urlComponents?.url else { throw Abort(.internalServerError) }

        let response = try await request.client.get(
            URI(string: uri.absoluteString)
//            headers: .init(
//                [("Accept-Encoding", "gzip")]
//            )
        )

        let responseBody = try response.content.decode(Components.Schemas.ParseResponse.self)
        let foods = responseBody.hints?.compactMap({ $0.asFoodItem() }) ?? []

        return foods
    }
}
