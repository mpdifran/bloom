//
//  DetectedFood.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-17.
//

import Foundation
import BloomModel

struct DetectedFood: Codable, Equatable, Sendable {
  let name: String
  let meal: SocketMessage.DetectedFood.Meal
  let foodItems: [OpenAIEstimateCaloriesResponse.Item]
}
