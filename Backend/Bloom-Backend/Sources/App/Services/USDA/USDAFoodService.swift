//
//  USDAFoodService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-11-11.
//

import Foundation
import Vapor
import BloomModel

struct USDAFoodService { }

extension USDAFoodService {

    func foundationFoodSearch(
        request: Request,
        query: String
    ) async throws -> [FoodItem] {

        var urlComponents = URLComponents(string: request.application.usdaDomain + "/v1/foods/search")
        urlComponents?.queryItems = [
            URLQueryItem(name: "api_key", value: request.application.usdaAPIKey)
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

        let response = try await request.client.post(
            URI(string: uri.absoluteString),
            content: requestBody
        )

        let responseBody = try response.content.decode(USDAFoodSearchResponse.self)
        let foodItems = responseBody.foods.compactMap({ $0.asFoodItem() })

        return foodItems
    }
}
