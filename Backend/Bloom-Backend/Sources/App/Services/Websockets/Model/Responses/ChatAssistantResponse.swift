//
//  ChatAssistantResponse.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-17.
//

import Foundation
import BloomModel

struct ChatAssistantResponse: Codable, Equatable, Sendable {
  let message: String
  let healthMetricGoals: [SocketMessage.HealthMetricGoal]?
  let detectedFood: DetectedFood?
}

struct DetectedFood: Codable, Equatable, Sendable {
  let name: String
  let foodItems: [OpenAIEstimateCaloriesResponse.Item]
}
