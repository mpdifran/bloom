//
//  GoalController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-02-20.
//

import Foundation
import Vapor
import BloomModel
import OpenAIKit

struct GoalController { }

extension GoalController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.auth(using: UserToken.self) {
        $0.group("goals") {
          $0.post("suggest", use: suggestGoals)
        }
      }
    }
  }
}

private extension GoalController {

  @Sendable
  func suggestGoals(_ request: Request) async throws -> SuggestGoalsResponse {
    let body = try request.content.decode(SuggestGoalsRequest.self)
    let user = try request.auth.require(User.self)

    guard let userID = user.id else {
      throw Abort(.unauthorized)
    }

    try await request.aiUsageLimiter.checkBudget(for: userID)

    return try await request.openAIService.suggestGoals(
      healthData: body.healthData,
      currentGoals: body.currentGoals,
      userID: userID
    )
  }
}
