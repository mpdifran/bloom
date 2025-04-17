//
//  SocketMessage+Messages.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-01.
//

public extension SocketMessage {
  struct MessageRequest: Codable, Equatable, Sendable {
    public let text: String
    public let imageFileIDs: [String]
    public let userInfo: String

    public init(
      text: String,
      imageFileIDs: [String],
      userInfo: String
    ) {
      self.text = text
      self.imageFileIDs = imageFileIDs
      self.userInfo = userInfo
    }
  }

  struct MessageResponse: Codable, Equatable, Sendable {
    public let message: String
    public let healthMetricGoals: [HealthMetricGoal]?
    public let detectedFood: DetectedFood?

    public init(
      message: String,
      healthMetricGoals: [HealthMetricGoal]?,
      detectedFood: DetectedFood?
    ) {
      self.message = message
      self.healthMetricGoals = healthMetricGoals
      self.detectedFood = detectedFood
    }
  }

  struct HealthMetricGoal: Codable, Equatable, Sendable {
    public let metric: SuggestedGoal.Metric
    public let value: Double
    public let unit: SuggestedGoal.Unit

    public init(
      metric: SuggestedGoal.Metric,
      value: Double,
      unit: SuggestedGoal.Unit
    ) {
      self.metric = metric
      self.value = value
      self.unit = unit
    }
  }

  struct DetectedFood: Codable, Equatable, Sendable {
    public let name: String
    public let foodItemServings: [EstimateFoodCaloriesResponse.Serving]

    public init(name: String, foodItemServings: [EstimateFoodCaloriesResponse.Serving]) {
      self.name = name
      self.foodItemServings = foodItemServings
    }
  }
}
