//
//  EdamamFoodController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-09.
//

import Foundation
import Vapor

struct EdamamFoodController {
    let app: Application

    init(app: Application) {
        self.app = app
    }
}

extension EdamamFoodController {

    func autocomplete(client: Client, query: String) async throws -> [String] {

        var urlComponents = URLComponents(string: app.edamamDomain + "/auto-complete")
        urlComponents?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "app_id", value: app.edamamAppID),
            URLQueryItem(name: "app_key", value: app.edamamAPIKey),
            URLQueryItem(name: "limit", value: "10")
        ]

        guard let uri = urlComponents?.url else { throw Abort(.internalServerError) }

        let response = try await client.get(URI(string: uri.absoluteString))
        return try response.content.decode([String].self)
    }
}
