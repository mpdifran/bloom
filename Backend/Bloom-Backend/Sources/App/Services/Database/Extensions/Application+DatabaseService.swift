//
//  Application+DatabaseService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-02.
//

import Vapor
import Fluent

extension Application {

  func userDatabaseService(db: any Database) -> UserDatabaseService {
    UserDatabaseService(db: db)
  }

  func foodDatabaseService(db: any Database) -> FoodDatabaseService {
    FoodDatabaseService(
      db: db,
      imageStorage: imageStorage
    )
  }

  func adminUserDatabaseService(db: any Database) -> AdminUserDatabaseService {
    AdminUserDatabaseService(db: db)
  }
}
