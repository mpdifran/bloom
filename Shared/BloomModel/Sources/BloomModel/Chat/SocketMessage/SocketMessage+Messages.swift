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
    public let logWaterConsumption: LogWaterConsumption?
    public let logBowelMovement: LogBowelMovement?
    public let logWeight: LogWeight?
    public let logBloodPressure: LogBloodPressure?

    public init(
      message: String,
      healthMetricGoals: [HealthMetricGoal]?,
      detectedFood: DetectedFood?,
      logWaterConsumption: LogWaterConsumption?,
      logBowelMovement: LogBowelMovement?,
      logWeight: LogWeight?,
      logBloodPressure: LogBloodPressure?
    ) {
      self.message = message
      self.healthMetricGoals = healthMetricGoals
      self.detectedFood = detectedFood
      self.logWaterConsumption = logWaterConsumption
      self.logBowelMovement = logBowelMovement
      self.logWeight = logWeight
      self.logBloodPressure = logBloodPressure
    }
  }
}

public extension SocketMessage {

  struct HealthMetricGoal: Codable, Equatable, Sendable {
    public let metric: SuggestedGoal.Metric
    public let timePeriod: SuggestedGoal.TimePeriod
    public let value: Double
    public let unit: SuggestedGoal.Unit

    public init(
      metric: SuggestedGoal.Metric,
      timePeriod: SuggestedGoal.TimePeriod,
      value: Double,
      unit: SuggestedGoal.Unit
    ) {
      self.metric = metric
      self.timePeriod = timePeriod
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

  struct LogWaterConsumption: Codable, Equatable, Sendable {
    public let quantity: Quantity

    public init(quantity: Quantity) {
      self.quantity = quantity
    }
  }

  struct LogBowelMovement: Codable, Equatable, Sendable {
    public let bristolStoolType: Int
    public let duration: Duration

    public init(bristolStoolType: Int, duration: Duration) {
      self.bristolStoolType = bristolStoolType
      self.duration = duration
    }

    public enum Duration: String, Codable, Equatable, Sendable, CaseIterable {
      case lessThan5Min
      case between5And10Min
      case moreThan10Min
    }
  }

  struct LogWeight: Codable, Equatable, Sendable {
    public let quantity: Quantity

    public init(quantity: Quantity) {
      self.quantity = quantity
    }
  }

  struct LogBloodPressure: Codable, Equatable, Sendable {
    public let systolic: Int
    public let diastolic: Int

    public init(systolic: Int, diastolic: Int) {
      self.systolic = systolic
      self.diastolic = diastolic
    }
  }
}
