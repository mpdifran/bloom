//
//  URLSession+Helpers.swift
//  Supplements
//
//  Created by Mark DiFranco on 2025-01-07.
//

import Foundation
import BloomModel

extension URLSession {

  func authenticatedBloomRequest(request: URLRequest) async throws {
    let authRequest = await request.settingBloomHeaders()
    let _ = try await URLSession.shared.data(for: authRequest)
  }

  func bloomRequestWithResponse<Response: Decodable>(
    request: URLRequest,
    responseType: Response.Type
  ) async throws -> Response {
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder.bloomModel.decode(Response.self, from: data)
  }

  func authenticatedBloomRequestWithResponse<Response: Decodable>(
    request: URLRequest,
    responseType: Response.Type
  ) async throws -> Response {
    let authRequest = await request.settingBloomHeaders()
    let (data, _) = try await URLSession.shared.data(for: authRequest)
    return try JSONDecoder.bloomModel.decode(Response.self, from: data)
  }
}
