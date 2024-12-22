//
//  JSONDecoder+OpenFoodFacts.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2024-12-21.
//

import Foundation

extension JSONDecoder {

  static let openFoodFacts: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    return decoder
  }()
}
