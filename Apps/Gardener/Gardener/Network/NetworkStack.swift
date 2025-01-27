//
//  NetworkStack.swift
//  Gardener
//
//  Created by Mark DiFranco on 2024-11-29.
//

import AdminBloomModel
import Foundation

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

  func createRequest(
    path: String,
    method: Method,
    queryItems: [URLQueryItem] = []
  ) -> URLRequest {
    let url = APIHost.shared.base
      .appendingPathComponent(path)
      .appending(queryItems: queryItems)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = method.rawValue

    return urlRequest
  }

  func createRequest<Content: Encodable>(
    path: String,
    method: Method,
    body: Content
  ) throws -> URLRequest {
    let url = APIHost.shared.base
      .appendingPathComponent(path)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = method.rawValue
    urlRequest.httpBody = try JSONEncoder.bloomModel.encode(body)
    urlRequest.add(header: .contentTypeJSON)

    return urlRequest
  }

  func createAuthenticatedRequest(
    path: String,
    method: Method,
    queryItems: [URLQueryItem] = []
  ) async -> URLRequest {
    let url = APIHost.shared.base
      .appendingPathComponent(path)
      .appending(queryItems: queryItems)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = method.rawValue

    return await urlRequest.settingBloomHeaders()
  }

  func createAuthenticatedRequest<Content: Encodable>(
    path: String,
    method: Method,
    body: Content
  ) async throws -> URLRequest {
    let url = APIHost.shared.base
      .appendingPathComponent(path)

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = method.rawValue
    urlRequest.httpBody = try JSONEncoder.bloomModel.encode(body)
    urlRequest.add(header: .contentTypeJSON)

    return await urlRequest.settingBloomHeaders()
  }
}

extension NetworkStack {

  func login(request: AuthenticationRequest) async throws -> AuthenticationResponse {
    let urlRequest = try createRequest(
      path: "v1/admin/auth/sign-in",
      method: .post,
      body: request
    )
    
    let (data, _) = try await URLSession.shared.data(for: urlRequest)
    
    return try JSONDecoder.bloomModel.decode(AuthenticationResponse.self, from: data)
  }

  func logout() async throws {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/user/logout",
      method: .get
    )

    _ = try await URLSession.shared.data(for: urlRequest)
  }

  func getUnverifiedFoodRecords(
    limit: Int = 100
  ) async throws -> UnverifiedFoodItemsResponse {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/food/unverified",
      method: .get,
      queryItems: [.init(name: "limit", value: "\(limit)")]
    )

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(UnverifiedFoodItemsResponse.self, from: data)
  }
  
  func createFoodRecord(
    request: AdminCreateFoodItemRequest
  ) async throws -> AdminCreateFoodItemResponse {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/food/create",
      method: .post,
      body: request
    )
    
    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(AdminCreateFoodItemResponse.self, from: data)
  }

  func updateFoodRecord(
    request: AdminUpdateFoodItemRequest
  ) async throws -> AdminUpdateFoodItemResponse {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/food/update",
      method: .patch,
      body: request
    )

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(AdminUpdateFoodItemResponse.self, from: data)
  }

  func deleteFoodRecord(id: FoodItemIdentifier) async throws {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/food/" + id.value,
      method: .delete
    )

    _ = try await URLSession.shared.data(for: urlRequest)
  }

  func searchFoodRecord(query: String) async throws -> AdminSearchFoodItemResponse {
    let urlRequest = await createAuthenticatedRequest(
      path: "v1/admin/food/search",
      method: .get,
      queryItems: [.init(name: "query", value: "\(query)")]
    )

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(AdminSearchFoodItemResponse.self, from: data)
  }

  func bulkUploadOpenFoodFacts(request: AdminOpenFoodFactsBulkUploadRequest) async throws -> AdminOpenFoodFactsBulkUploadResponse {
    let urlRequest = try await createAuthenticatedRequest(
      path: "v1/admin/food/open-food-facts/bulk-upload",
      method: .post,
      body: request
    )

    let (data, _) = try await URLSession.shared.data(for: urlRequest)

    return try JSONDecoder.bloomModel.decode(AdminOpenFoodFactsBulkUploadResponse.self, from: data)
  }
}
