//
//  OpenAIGenerateWorkoutPlanResponse.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2026-02-11.
//

import Foundation
import BloomModel

struct OpenAIGenerateWorkoutPlanResponse: Codable {
  let title: String
  let summary: String
  let requiredEquipment: [String]
  let sets: [SocketMessage.WorkoutSet]

  func toWorkoutPlan() -> SocketMessage.WorkoutPlan {
    let equipment = requiredEquipment.compactMap {
      SocketMessage.WorkoutPlan.Equipment(rawValue: $0)
    }
    return SocketMessage.WorkoutPlan(
      title: title,
      summary: summary,
      requiredEquipment: equipment,
      sets: sets
    )
  }
}
