//
//  Request+OpenFoodFacts.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-02.
//

import Vapor

extension Request {

  var openFoodFactsService: OpenFoodFactsService {
    application.openFoodFactsService(
      db: db,
      client: client,
      logger: logger
    )
  }
}
