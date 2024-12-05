//
//  OpenFoodFactsService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-05.
//

import Vapor

struct OpenFoodFactsService {
  let baseURL = URL(string: "https://world.openfoodfacts.net/api/v2/")!
  var defaultHeaders: HTTPHeaders = {
    var headers = HTTPHeaders()
    headers.add(name: .userAgent, value: "Bloom-Backend/1.0 (hello@trybloom.app)")
    return headers
  }()
}

extension OpenFoodFactsService {

  func fetchProductImages(_ request: Request, barcode: String) async throws -> OpenFoodFactsProductResponse {
    let url = baseURL
      .appending(component: "product")
      .appending(component: barcode)

    let response = try await request.client.get(URI(string: url.absoluteString), headers: defaultHeaders)

    return try response.content.decode(OpenFoodFactsProductResponse.self)
  }
}
