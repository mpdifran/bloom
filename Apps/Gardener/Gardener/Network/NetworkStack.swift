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
  enum Method: String {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
  }

  enum NetworkError: Error {
    case invalidURL
  }

  func request<Response: Decodable, Content: Encodable>(
    path: String,
    method: Method,
    body: Content?,
    responseType: Response.Type
  ) async throws -> Response {
    guard let url = URL(string: APIHost.shared.base + path) else {
      throw NetworkError.invalidURL
    }
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = method.rawValue

    if let body {
      urlRequest.httpBody = try JSONEncoder.bloomModel.encode(body)
      urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    let (data, _) = try await URLSession.shared.data(for: urlRequest)
    guard data.isNotEmpty else {
      // If there is no data, return an EmptyResponse.
      return EmptyResponse() as! Response
    }
    return try JSONDecoder.bloomModel.decode(Response.self, from: data)
  }

  func request<Response: Decodable>(
    path: String,
    method: Method,
    responseType: Response.Type
  ) async throws -> Response {
    try await request(
      path: path,
      method: method,
      body: Optional<String>.none, // handle no body.
      responseType: responseType
    )
  }
}

extension NetworkStack {
  func getUnverifiedFoodRecords(
    limit: Int = 100
  ) async throws -> UnverifiedFoodItemsResponse {
    let path = "v1/admin/food/unverified?limit=\(limit)"

    return try await request(
      path: path,
      method: .get,
      responseType: UnverifiedFoodItemsResponse.self
    )
  }

  func updateFoodRecord(
    request body: AdminUpdateFoodItemRequest
  ) async throws -> AdminUpdateFoodItemResponse {
    let path = "v1/admin/food/update"

    return try await request(
      path: path,
      method: .patch,
      body: body,
      responseType: AdminUpdateFoodItemResponse.self
    )
  }

  func deleteFoodRecord(id: FoodItemIdentifier) async throws {
    let path = "v1/admin/food/" + id.value

    _ = try await request(
      path: path,
      method: .delete,
      responseType: EmptyResponse.self
    )
  }

  func searchFoodRecord(query: String) async throws -> AdminSearchFoodItemResponse {
    let path = "v1/admin/food/search?query=\(query)"

    return try await request(
      path: path,
      method: .get,
      responseType: AdminSearchFoodItemResponse.self
    )
  }

  func bulkUploadOpenFoodFacts(
    request body: AdminOpenFoodFactsBulkUploadRequest
  ) async throws -> AdminOpenFoodFactsBulkUploadResponse {
    let path = "v1/admin/food/open-food-facts/bulk-upload"

    return try await request(
      path: path,
      method: .post,
      body: body,
      responseType: AdminOpenFoodFactsBulkUploadResponse.self
    )
  }
}
