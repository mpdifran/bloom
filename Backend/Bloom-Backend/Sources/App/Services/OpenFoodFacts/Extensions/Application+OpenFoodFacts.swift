//
//  Application+OpenFoodFacts.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-02.
//

import Vapor
import Fluent

extension Application {

  func openFoodFactsService(db: any Database, client: Client, logger: Logger) -> OpenFoodFactsService {
    OpenFoodFactsService(
      db: db,
      client: client,
      logger: logger,
      foodDatabaseService: foodDatabaseService(db: db),
      openAIService: openAIService
    )
  }
}
