//
//  OpenFoodFactsSearchResponse.swift
//  Bloom-Backend
//
//  Created by Claude Code on 2025-11-25.
//

import Foundation

struct OpenFoodFactsSearchResponse: Codable {
  let count: Int
  let page: Int
  let pageSize: Int
  let products: [OpenFoodFactsProduct]

  enum CodingKeys: String, CodingKey {
    case count
    case page
    case pageSize = "page_size"
    case products
  }
}
