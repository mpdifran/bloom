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
    public let requestID: String?

    public init(
      text: String,
      imageFileIDs: [String],
      userInfo: String,
      requestID: String? = nil
    ) {
      self.text = text
      self.imageFileIDs = imageFileIDs
      self.userInfo = userInfo
      self.requestID = requestID
    }
  }

  struct MessageChunkResponse: Codable, Equatable, Sendable {
    public let id: String
    public let chunk: String
    public let requestID: String?

    public init(
      id: String,
      chunk: String,
      requestID: String? = nil
    ) {
      self.id = id
      self.chunk = chunk
      self.requestID = requestID
    }
  }

  struct MessageResponse: Codable, Equatable, Sendable {
    public let id: String
    public let message: String
    public let requestID: String?

    public init(
      id: String,
      message: String,
      requestID: String? = nil
    ) {
      self.id = id
      self.message = message
      self.requestID = requestID
    }
  }

  struct RichMessageResponse: Codable, Equatable, Sendable {
    public let id: String
    public let kind: Kind
    public let isTemporary: Bool
    public let requestID: String?

    public init(
      id: String,
      kind: Kind,
      isTemporary: Bool,
      requestID: String? = nil
    ) {
      self.id = id
      self.kind = kind
      self.isTemporary = isTemporary
      self.requestID = requestID
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
      case createReminder(SocketMessage.CreateReminder)
      case deleteReminder(SocketMessage.DeleteReminder)
      case invalid(String)
    }
  }
}
