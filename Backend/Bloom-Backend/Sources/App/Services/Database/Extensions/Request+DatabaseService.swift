//
//  Request+DatabaseService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-02.
//

import Vapor
import Fluent

extension Request {

  var userDatabaseService: UserDatabaseService {
    application.userDatabaseService(db: db)
  }

  var foodDatabaseService: FoodDatabaseService {
    application.foodDatabaseService(db: db)
  }

  var adminUserDatabaseService: AdminUserDatabaseService {
    application.adminUserDatabaseService(db: db)
  }
}
