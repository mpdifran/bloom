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

  struct MessageChunkResponse: Codable, Equatable, Sendable {
    public let id: String
    public let chunk: String

    public init(
      id: String,
      chunk: String
    ) {
      self.id = id
      self.chunk = chunk
    }
  }

  struct MessageResponse: Codable, Equatable, Sendable {
    public let id: String
    public let message: String

    public init(
      id: String,
      message: String
    ) {
      self.id = id
      self.message = message
    }
  }

  struct RichMessageResponse: Codable, Equatable, Sendable {
    public let id: String
    public let kind: Kind
    public let isTemporary: Bool

    public init(
      id: String,
      kind: Kind,
      isTemporary: Bool
    ) {
      self.id = id
      self.kind = kind
      self.isTemporary = isTemporary
    }

    public enum Kind: Codable, Equatable, Sendable {
      case newGoals([SocketMessage.HealthMetricGoal])
      case detectedFood(SocketMessage.DetectedFood)
      case logWeight(SocketMessage.LogWeight)
      case logPeriod(SocketMessage.LogPeriod)
      case logWater(SocketMessage.LogWaterConsumption)
      case logBloodPressure(SocketMessage.LogBloodPressure)
      case logBowelMovement(SocketMessage.LogBowelMovement)
      case createWorkout(SocketMessage.WorkoutPlan)
      case invalid(String)
    }
  }
}
