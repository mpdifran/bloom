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
    public let extraSystemContext: String?
    public let requestID: String?
    public let lastMessageID: String?
    public let conversationID: String?

    /// BCP-47 tag for the language the client's UI is running in, e.g. "es-MX".
    ///
    /// Optional for backwards compatibility: clients shipped before this existed send nothing, and
    /// the server leaves the assistant's language behaviour untouched in that case.
    public let locale: String?

    public var isV2: Bool {
      conversationID != nil
    }

    public init(
      text: String,
      imageFileIDs: [String],
      userInfo: String,
      extraSystemContext: String? = nil,
      requestID: String? = nil,
      lastMessageID: String? = nil,
      conversationID: String? = nil,
      locale: String? = nil
    ) {
      self.text = text
      self.imageFileIDs = imageFileIDs
      self.userInfo = userInfo
      self.extraSystemContext = extraSystemContext
      self.requestID = requestID
      self.lastMessageID = lastMessageID
      self.conversationID = conversationID
      self.locale = locale
    }
  }

  struct MessageChunkResponse: Codable, Equatable, Sendable {
    public let id: String
    public let chunk: String
    public let requestID: String?
    public let conversationID: String?

    public init(
      id: String,
      chunk: String,
      requestID: String? = nil,
      conversationID: String? = nil
    ) {
      self.id = id
      self.chunk = chunk
      self.requestID = requestID
      self.conversationID = conversationID
    }
  }

  struct MessageResponse: Codable, Equatable, Sendable {
    public let id: String
    public let message: String
    public let requestID: String?
    public let responseID: String?
    public let conversationID: String?

    public init(
      id: String,
      message: String,
      requestID: String? = nil,
      responseID: String? = nil,
      conversationID: String? = nil
    ) {
      self.id = id
      self.message = message
      self.requestID = requestID
      self.responseID = responseID
      self.conversationID = conversationID
    }
  }

  struct RichMessageResponse: Codable, Equatable, Sendable {
    public let id: String
    public let kind: Kind
    public let isTemporary: Bool
    public let requestID: String?
    public let responseID: String?
    public let conversationID: String?

    public init(
      id: String,
      kind: Kind,
      isTemporary: Bool,
      requestID: String? = nil,
      responseID: String? = nil,
      conversationID: String? = nil
    ) {
      self.id = id
      self.kind = kind
      self.isTemporary = isTemporary
      self.requestID = requestID
      self.responseID = responseID
      self.conversationID = conversationID
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
      case createUserFacts(SocketMessage.CreateUserFacts)
      case deleteUserFacts(SocketMessage.DeleteUserFacts)
      case invalid(String)
    }
  }
}
