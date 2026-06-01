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

    /// Fetch a paginated list of full-detail USDA foods for a given dataset.
    /// Two-step under the hood: `/v1/foods/list` for fdcIds, then `/v1/foods` for full
    /// detail (in batches of ≤20, the FDC limit). Returns items in the
    /// `USDAImportFoodItem` shape ready to feed into the existing mapper.
    func listFullFoods(
        request: Request,
        dataType: USDADataType,
        pageSize: Int,
        pageNumber: Int
    ) async throws -> [USDAImportFoodItem] {
        let listIDs = try await listFoodIDs(
            request: request,
            dataType: dataType,
            pageSize: pageSize,
            pageNumber: pageNumber
        )
        guard !listIDs.isEmpty else { return [] }

        var results: [USDAImportFoodItem] = []
        results.reserveCapacity(listIDs.count)

        // FDC `/v1/foods` accepts up to 20 fdcIds per call.
        for chunk in listIDs.chunked(into: 20) {
            let chunkResults = try await fetchFoods(request: request, fdcIds: chunk)
            results.append(contentsOf: chunkResults)
        }
        return results
    }

    private func listFoodIDs(
        request: Request,
        dataType: USDADataType,
        pageSize: Int,
        pageNumber: Int
    ) async throws -> [Int] {
        var urlComponents = URLComponents(string: request.application.usdaDomain + "/v1/foods/list")
        urlComponents?.queryItems = [
            URLQueryItem(name: "api_key", value: request.application.usdaAPIKey),
            URLQueryItem(name: "dataType", value: dataType.fdcQueryValue),
            URLQueryItem(name: "pageSize", value: "\(pageSize)"),
            URLQueryItem(name: "pageNumber", value: "\(pageNumber)")
        ]
        guard let uri = urlComponents?.url else { throw Abort(.internalServerError) }

        let response = try await request.client.get(URI(string: uri.absoluteString))
        let abridged = try response.content.decode([USDAFoodItem].self)
        return abridged.map { $0.fdcId }
    }

    private func fetchFoods(
        request: Request,
        fdcIds: [Int]
    ) async throws -> [USDAImportFoodItem] {
        var urlComponents = URLComponents(string: request.application.usdaDomain + "/v1/foods")
        urlComponents?.queryItems = [
            URLQueryItem(name: "api_key", value: request.application.usdaAPIKey)
        ]
        guard let uri = urlComponents?.url else { throw Abort(.internalServerError) }

        struct Body: Content {
            let fdcIds: [Int]
            let format: String
        }
        let body = Body(fdcIds: fdcIds, format: "full")

        let response = try await request.client.post(
            URI(string: uri.absoluteString),
            content: body
        )
        return try response.content.decode([USDAImportFoodItem].self)
    }
}

enum USDADataType: String, Codable {
    case foundation
    case srLegacy = "sr_legacy"

    /// Value accepted by the FDC API `dataType` query param.
    var fdcQueryValue: String {
        switch self {
        case .foundation: return "Foundation"
        case .srLegacy:   return "SR Legacy"
        }
    }
}

