//
//  URLSession+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-07.
//

import Foundation
import BloomModel

public extension URLSession {

  func authenticatedBloomRequest(request: URLRequest) async throws {
    let authRequest = await request.settingBloomHeaders()
    let _ = try await URLSession.shared.data(for: authRequest)
  }

  func bloomRequestWithResponse<Response: Decodable>(
    request: URLRequest,
    responseType: Response.Type
  ) async throws -> Response {
    let (data, response) = try await URLSession.shared.data(for: request)
    try Self.validate(response: response, data: data)
    return try JSONDecoder.bloomModel.decode(Response.self, from: data)
  }

  func authenticatedBloomRequestWithResponse<Response: Decodable>(
    request: URLRequest,
    responseType: Response.Type
  ) async throws -> Response {
    let authRequest = await request.settingBloomHeaders()
    let (data, response) = try await URLSession.shared.data(for: authRequest)
    try Self.validate(response: response, data: data)
    return try JSONDecoder.bloomModel.decode(Response.self, from: data)
  }

  /// Throws a `ServerError` (carrying the backend's `reason`) on a non-2xx response, so callers
  /// surface the server's user-facing message rather than a generic decoding failure. Non-HTTP
  /// responses are passed through unchanged.
  private static func validate(response: URLResponse, data: Data) throws {
    guard let http = response as? HTTPURLResponse else { return }
    guard (200..<300).contains(http.statusCode) else {
      throw ServerError.decode(statusCode: http.statusCode, data: data)
        ?? ServerError(statusCode: http.statusCode, reason: "Something went wrong. Please try again.")
    }
  }
}
