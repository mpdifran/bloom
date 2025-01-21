//
//  NetworkStack.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-11-29.
//

import AdminBloomModel
import Foundation

struct EmptyResponse: Decodable {}

final class NetworkStack: Sendable {
  static let shared = NetworkStack()
}

private extension NetworkStack {
  func get<Response>(
    url: URL,
    response: Response.Type
  ) async throws -> Response where Response: Decodable {

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "GET"

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(Response.self, from: data)
  }

  func post<Content, Response>(
    url: URL,
    body: Content,
    response: Response.Type
  ) async throws -> Response where Content: Encodable, Response: Decodable {

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.httpBody = try JSONEncoder.bloomModel.encode(body)
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(Response.self, from: data)
  }

  func patch<Content, Response>(
    url: URL,
    body: Content,
    response: Response.Type
  ) async throws -> Response where Content: Encodable, Response: Decodable {

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "PATCH"
    urlRequest.httpBody = try JSONEncoder.bloomModel.encode(body)
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(Response.self, from: data)
  }

  func delete(
    url: URL
  ) async throws {

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "DELETE"

    _ = try await URLSession.shared.data(for: urlRequest)
  }
}

extension NetworkStack {
  func getUnverifiedFoodRecords(
    limit: Int = 100
  ) async throws -> UnverifiedFoodItemsResponse {
    let url = URL(string: APIHost.shared.base + "v1/admin/food/unverified?limit=\(limit)")!

    return try await get(
      url: url,
      response: UnverifiedFoodItemsResponse.self
    )
  }

  func updateFoodRecord(
    request: AdminUpdateFoodItemRequest
  ) async throws -> AdminUpdateFoodItemResponse {
    let url = URL(string: APIHost.shared.base + "v1/admin/food/update")!

    return try await patch(
      url: url,
      body: request,
      response: AdminUpdateFoodItemResponse.self
    )
  }

  func deleteFoodRecord(id: FoodItemIdentifier) async throws {
    let url = URL(string: APIHost.shared.base + "v1/admin/food/" + id.value)!

    try await delete(url: url)
  }

  func searchFoodRecord(query: String) async throws -> AdminSearchFoodItemResponse {
    let url = URL(string: APIHost.shared.base + "v1/admin/food/search?query=\(query)")!

    return try await get(
      url: url,
      response: AdminSearchFoodItemResponse.self
    )
  }

  func bulkUploadOpenFoodFacts(request: AdminOpenFoodFactsBulkUploadRequest) async throws -> AdminOpenFoodFactsBulkUploadResponse {
    let url = URL(string: APIHost.shared.base + "v1/admin/food/open-food-facts/bulk-upload")!

    return try await post(
      url: url,
      body: request,
      response: AdminOpenFoodFactsBulkUploadResponse.self
    )
  }
}
