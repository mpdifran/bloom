//
//  ScoketMessage+RichContent.swift
//  bloom-model
//
//  Created by Mark DiFranco on 2025-04-27.
//

import Foundation

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
    public let amount: Double
    public let unit: Unit

    public init(amount: Double, unit: Unit) {
      self.amount = amount
      self.unit = unit
    }

    public enum Unit: String, Codable, Equatable, Sendable, CaseIterable {
      case mL
      case ozUS = "fl_oz_us"
      case ozUK = "fl_oz" // TODO: Double check this.
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
    public let value: Double
    public let unit: Unit

    public init(value: Double, unit: Unit) {
      self.value = value
      self.unit = unit
    }

    public enum Unit: String, Codable, Equatable, Sendable, CaseIterable {
      case lb
      case kg
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
