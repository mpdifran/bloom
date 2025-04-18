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
  let logWaterConsumption: SocketMessage.LogWaterConsumption?
  let logBowelMovement: SocketMessage.LogBowelMovement?
  let logWeight: SocketMessage.LogWeight?
  let logBloodPressure: SocketMessage.LogBloodPressure?
}

struct DetectedFood: Codable, Equatable, Sendable {
  let name: String
  let foodItems: [OpenAIEstimateCaloriesResponse.Item]
}
