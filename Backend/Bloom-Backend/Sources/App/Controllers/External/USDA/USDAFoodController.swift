//
//  USDAFoodController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Vapor
import BloomModel

struct USDAFoodController {
    let app: Application

    init(app: Application) {
        self.app = app
    }
}

extension USDAFoodController {

    func foundationFoodSearch(
        client: Client,
        query: String
    ) async throws -> [FoodItem] {

        var urlComponents = URLComponents(string: app.usdaDomain + "/v1/foods/search")
        urlComponents?.queryItems = [
            URLQueryItem(name: "api_key", value: app.usdaAPIKey)
        ]

        let requestBody = USDAFoodSearchRequest(
            query: query,
            dataType: ["Foundation"],
            pageSize: 5,
            pageNumber: 0,
            sortBy: "dataType.keyword",
            sortOrder: "asc"
        )

        guard let uri = urlComponents?.url else { throw Abort(.internalServerError) }

        let response = try await client.post(
            URI(string: uri.absoluteString),
            content: requestBody
        )
        let responseBody = try response.content.decode(USDAFoodSearchResponse.self)
        let foodItems = responseBody.foods.compactMap({ $0.asFoodItem() })

        return foodItems
    }
}
