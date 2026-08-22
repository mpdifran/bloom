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

    /// BCP-47 tag for the language the app's interface is displayed in.
    ///
    /// Differs from `locale` when the user's language isn't one we ship a localization for: Bud can
    /// write Dutch even though the UI is English, and needs to know that so it names UI labels in
    /// the language the user actually sees on screen.
    public let interfaceLocale: String?

    /// What this client understands of the chat protocol.
    ///
    /// Optional for the same reason `locale` is: clients shipped before it existed send nothing,
    /// and the server has to keep treating `nil` as "legacy" indefinitely. Capabilities are gated
    /// on this rather than on the app version, which changes far more often than the protocol.
    ///
    /// Version 1 means the client can render ``SocketMessage/SourceRef``, so it may be sent web
    /// search results.
    public let protocolVersion: Int?

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
      locale: String? = nil,
      interfaceLocale: String? = nil,
      protocolVersion: Int? = nil
    ) {
      self.text = text
      self.imageFileIDs = imageFileIDs
      self.userInfo = userInfo
      self.extraSystemContext = extraSystemContext
      self.requestID = requestID
      self.lastMessageID = lastMessageID
      self.conversationID = conversationID
      self.locale = locale
      self.interfaceLocale = interfaceLocale
      self.protocolVersion = protocolVersion
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
    /// Web pages this message drew on. Only ever sent to clients that asked for protocol
    /// version 1 or higher, so in practice a client receiving this can render it.
    public let sources: [SourceRef]?

    public init(
      id: String,
      message: String,
      requestID: String? = nil,
      responseID: String? = nil,
      conversationID: String? = nil,
      sources: [SourceRef]? = nil
    ) {
      self.id = id
      self.message = message
      self.requestID = requestID
      self.responseID = responseID
      self.conversationID = conversationID
      self.sources = sources
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
