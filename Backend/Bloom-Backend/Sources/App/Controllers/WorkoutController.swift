//
//  WorkoutController.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2026-02-11.
//

import Foundation
import Vapor
import BloomModel

struct WorkoutController { }

extension WorkoutController: RouteCollection {

  func boot(routes: any RoutesBuilder) throws {
    routes.group("v1") {
      $0.auth(using: UserToken.self) {
        $0.group("workouts") {
          $0.post("generate-plan", use: generatePlan)
        }
      }
    }
  }
}

private extension WorkoutController {

  @Sendable
  func generatePlan(_ request: Request) async throws -> GenerateWorkoutPlanResponse {
    let body = try request.content.decode(GenerateWorkoutPlanRequest.self)
    let user = try request.auth.require(User.self)

    guard let userID = user.id else {
      throw Abort(.unauthorized)
    }

    try await request.aiUsageLimiter.checkBudget(for: userID)

    let workoutPlan = try await request.openAIService.generateWorkoutPlan(
      equipment: body.equipment,
      description: body.description,
      locale: body.locale,
      userID: userID
    )

    return GenerateWorkoutPlanResponse(workoutPlan: workoutPlan)
  }
}
