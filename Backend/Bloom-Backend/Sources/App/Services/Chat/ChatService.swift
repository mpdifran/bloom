//
//  ChatService.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-04-21.
//

import Foundation
import Vapor
import BloomModel
import OpenAIKit
import Fluent
import APNS
import APNSCore
import Redis

// MARK: - ChatService

final class ChatService: Sendable {

  private let application: Application
  private let logger: Logger

  init(
    application: Application,
    logger: Logger
  ) {
    self.application = application
    self.logger = logger
  }

  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel
}

// MARK: - Public Methods

extension ChatService {

  func parse(
    data: Data,
    for userID: UserIdentifier,
    db: any Database
  ) async throws -> Bool {
    if let message = try? decoder.decode(SocketMessage.MessageRequest.self, from: data) {
      try await on(message: message, userID: userID, db: db)
    } else if let toolCallResponse = try? decoder.decode(SocketMessage.ToolCallsResponse.self, from: data) {
      try await onToolCallsResponse(response: toolCallResponse, userID: userID, db: db)
    } else {
      return false
    }
    return true
  }
}

// MARK: - Incoming Message Handlers

private extension ChatService {

  func on(
    message: SocketMessage.MessageRequest,
    userID: UserIdentifier,
    db: any Database
  ) async throws {
    let assistantService = application.openAIAssistantService(db: db)

    guard let thread = try await assistantService.createOrFetchAssistantThread(
      userID: userID,
      assistantSpec: .healthCoach
    ) else {
      logger.info("Received WebSocket message from unknown user \(userID).")
      return
    }

    try await assistantService.cancelCurrentlyActiveRuns(assistantThread: thread)

    var content = [OpenAIKit.Thread.Message.Content]()
    content.append(.text("Here are some details about me:\n\n\(message.userInfo)"))
    for fileID in message.imageFileIDs {
      content.append(.imageFile(fileID, .auto))
    }
    content.append(.text(message.text))

    try await assistantService.sendChatContent(
      assistantThread: thread,
      content: content
    )

    try await performRun(
      thread: thread,
      userID: userID,
      db: db
    )
  }

  func onToolCallsResponse(
    response: SocketMessage.ToolCallsResponse,
    userID: UserIdentifier,
    db: any Database
  ) async throws {
    let assistantService = application.openAIAssistantService(db: db)

    guard let thread = try await assistantService.createOrFetchAssistantThread(
      userID: userID,
      assistantSpec: .healthCoach
    ) else {
      logger.info("Received WebSocket message from unknown user \(userID).")
      return
    }

    let toolOutputs = response.toolCallResults.map {
      ToolOutput(toolCallID: $0.toolCallID, output: $0.data)
    }

    let run = try await assistantService.submitSuccessfulToolOputput(
      threadID: thread.threadID,
      runID: response.runID,
      toolOutputs: toolOutputs
    )

    try await performRun(
      thread: thread,
      existingRun: run,
      userID: userID,
      db: db
    )
  }
}

// MARK: - Communication Methods

private extension ChatService {

  func socket(for userID: UserIdentifier) async -> WebSocket? {
    let webSocketService = application.webSocketService

    return await webSocketService.webSocket(for: userID)
  }

  func sendSocketContentIfAvailable<Content>(
    _ content: Content,
    userID: UserIdentifier
  ) async throws where Content: Encodable {
    guard let socket = await socket(for: userID) else {
      return
    }
    try socket.sendContent(content)
    logger.debug("Sent web socket message to \(userID)")
  }

  func sendIsAssistantTyping(
    isTyping: Bool,
    userID: UserIdentifier
  ) async throws {
    let typingIndicator = SocketMessage.TypingIndicator(isTyping: isTyping)
    try await sendSocketContentIfAvailable(typingIndicator, userID: userID)
  }

  func ensureContentSent<Content>(
    _ content: Content,
    title: String,
    message: String,
    userID: UserIdentifier,
    db: any Database
  ) async throws where Content: Encodable, Content: Sendable {
    if let socket = await socket(for: userID) {
      try socket.sendContent(content)
      logger.debug("Sent web socket message to \(userID)")
      return
    }

    let userDatabaseService = application.userDatabaseService(db: db)

    guard let user = try await userDatabaseService.fetchUser(for: userID) else {
      logger.info("Attempting to send message to unknown user \(userID).")
      return
    }

    let threadID = "bud-assistant-chat" // This is used for the APNs but also redis

    if let deviceToken = user.apnsDeviceToken {
      let expirationTime = Int(Date().addingTimeInterval(3600).timeIntervalSince1970)
      let expiration = APNSNotificationExpiration.timeIntervalSince1970InSeconds(expirationTime)
      let priority = APNSPriority.immediately
      let topic = application.bloomAppBundleID

      let alertContent = APNSAlertNotificationContent(
        title: .raw(title),
        body: .raw(message)
      )

      let alertNotification = APNSAlertNotification(
        alert: alertContent,
        expiration: expiration,
        priority: priority,
        topic: topic,
        payload: content,
        sound: .default, // Can add badge here eventually
        threadID: threadID
      )

      let result = try await application.apns.client.send(
        APNSRequest(
          message: alertNotification,
          deviceToken: deviceToken,
          pushType: .alert,
          expiration: expiration,
          priority: priority,
          apnsID: nil,
          topic: topic,
          collapseID: nil
        )
      )

      if let apnsUniqueID = result.apnsUniqueID {
        logger.debug("Sent APNS message to \(userID): \(apnsUniqueID)")
      }
    } else {
      logger.debug("Could not relay message to user \(userID).")
//      let key = RedisKey("\(threadID):\(userID.value)")
//      let data = try encoder.encode(content)
//
//      let result = try await application.redis.rpush([data], into: key).get()
//      let _ = try await application.redis.expire(key, after: .seconds(86400)).get()
    }
  }

  func ensureContentSilentlySent<Content>(
    _ content: Content,
    userID: UserIdentifier,
    db: any Database
  ) async throws where Content: Encodable, Content: Sendable {
    if let socket = await socket(for: userID) {
      try socket.sendContent(content)
      logger.debug("Sent web socket message to \(userID)")
      return
    }

    let userDatabaseService = application.userDatabaseService(db: db)

    guard let user = try await userDatabaseService.fetchUser(for: userID) else {
      logger.info("Attempting to send message to unknown user \(userID).")
      return
    }

    let threadID = "bud-assistant-query" // This is used for the APNs but also redis

    if let deviceToken = user.apnsDeviceToken {
      let expirationTime = Int(Date().addingTimeInterval(3600).timeIntervalSince1970)
      let expiration = APNSNotificationExpiration.timeIntervalSince1970InSeconds(expirationTime)
      let priority = APNSPriority.immediately
      let topic = application.bloomAppBundleID

      let silentNotification = APNSBackgroundNotification(
        expiration: expiration,
        topic: topic,
        payload: content
      )

      let result = try await application.apns.client.send(
        APNSRequest(
          message: silentNotification,
          deviceToken: deviceToken,
          pushType: .background,
          expiration: expiration,
          priority: priority,
          apnsID: nil,
          topic: topic,
          collapseID: nil
        )
      )

      if let apnsUniqueID = result.apnsUniqueID {
        logger.debug("Sent silent APNS message to \(userID): \(apnsUniqueID)")
      }
    } else {
      logger.debug("Could not relay silent message to user \(userID).")

      // TODO: Store in redis? Or cancel run?
    }
  }
}

// MARK: - Run Management

private extension ChatService {

  func performRun(
    thread: OpenAIAssistantThread,
    existingRun: Run? = nil,
    userID: UserIdentifier,
    db: any Database
  ) async throws {
    let assistantService = application.openAIAssistantService(db: db)

    try await sendIsAssistantTyping(isTyping: true, userID: userID)

    let assistantResponse = try await assistantService.startRunAndPollForResponse(
      assistantThread: thread,
      tools: [
        Assistant.Tool.function(.queryUserHealthData),
        Assistant.Tool.function(.queryUserHealthMetrics),
        Assistant.Tool.function(.setGoals),
        Assistant.Tool.function(.logFood),
        Assistant.Tool.function(.logWater),
        Assistant.Tool.function(.logWeight),
        Assistant.Tool.function(.logBloodPressure),
        Assistant.Tool.function(.logBowelMovement),
        Assistant.Tool.function(.createWorkoutPlan),
      ],
      toolChoice: .auto,
      existingRun: existingRun
    )

    switch assistantResponse {
    case .requiresAction(let run, let toolCalls):
      var toolCallWrappers = [SocketMessage.ToolCallWrapper]()
      for toolCall in toolCalls {
        switch toolCall.function.name {
        case .Function.queryUserHealthData, .Function.queryUserHealthMetrics:
          toolCallWrappers.append(try await performQuery(toolCall: toolCall))
        case .Function.setGoals:
          toolCallWrappers.append(try await setGoals(toolCall: toolCall))
        case .Function.logFood:
          toolCallWrappers.append(try await logFood(toolCall: toolCall))
        case .Function.logWater:
          toolCallWrappers.append(try await logWater(toolCall: toolCall))
        case .Function.logWeight:
          toolCallWrappers.append(try await logWeight(toolCall: toolCall))
        case .Function.logBloodPressure:
          toolCallWrappers.append(try await logBloodPressure(toolCall: toolCall))
        case .Function.logBowelMovement:
          toolCallWrappers.append(try await logBowelMovements(toolCall: toolCall))
        case .Function.createWorkoutPlan:
          toolCallWrappers.append(try await createWorkout(toolCall: toolCall))
        default:
          throw Abort(.internalServerError, reason: "Unsupported tool function: \(toolCall.function.name)")
        }
      }
      let toolCallRequest = SocketMessage.ToolCallsRequest(
        runID: run.id,
        toolCalls: toolCallWrappers
      )
      try await ensureContentSilentlySent(toolCallRequest, userID: userID, db: db)
    case .messages(_, let messages):
      let message = messages.flatMap { $0.content.compactMap({ $0.text }) }.first

      guard let message else {
        throw Abort(.internalServerError, reason: "Could not decode message from Assistant.")
      }

      let response = SocketMessage.MessageResponse(message: message)

      try await sendIsAssistantTyping(isTyping: false, userID: userID)
      try await ensureContentSent(
        response,
        title: "Bud",
        message: response.message,
        userID: userID,
        db: db
      )
    }
  }
}

// MARK: - Function Handlers

private extension ChatService {

  func performQuery(toolCall: Run.ToolCall) async throws -> SocketMessage.ToolCallWrapper {
    switch toolCall.function.name {
    case .Function.queryUserHealthData:
      let queryArguments = try toolCall.decodeArguments(type: QueryUserHealthDataArguments.self, using: decoder)
      let query = SocketMessage.Query(
        startDate: queryArguments.startDate,
        endDate: queryArguments.endDate,
        dataType: queryArguments.dataType,
        healthMetric: nil
      )
      return SocketMessage.ToolCallWrapper(toolCallID: toolCall.id, kind: .query(query))
    case .Function.queryUserHealthMetrics:
      let queryArguments = try toolCall.decodeArguments(type: QueryUserHealthMetricsArguments.self, using: decoder)
      let query = SocketMessage.Query(
        startDate: queryArguments.startDate,
        endDate: queryArguments.endDate,
        dataType: nil,
        healthMetric: queryArguments.healthMetric
      )
      return SocketMessage.ToolCallWrapper(toolCallID: toolCall.id, kind: .query(query))
    default:
      throw Abort(.internalServerError, reason: "Improper tool handling")
    }
  }

  func setGoals(toolCall: Run.ToolCall) async throws -> SocketMessage.ToolCallWrapper {
    guard toolCall.function.name == .Function.setGoals else {
      throw Abort(.internalServerError, reason: "Improper tool handling")
    }

    let arguments = try toolCall.decodeArguments(type: SetGoalsArguments.self, using: decoder)

    return SocketMessage.ToolCallWrapper(toolCallID: toolCall.id, kind: .newGoals(arguments.newGoals))
  }

  func logFood(toolCall: Run.ToolCall) async throws -> SocketMessage.ToolCallWrapper {
    guard toolCall.function.name == .Function.logFood else {
      throw Abort(.internalServerError, reason: "Improper tool handling")
    }

    let arguments = try toolCall.decodeArguments(type: DetectedFood.self, using: decoder)

    let detectedFood = SocketMessage.DetectedFood(
      name: arguments.name,
      meal: arguments.meal,
      foodItemServings: arguments.foodItems.map { $0.asServing() }
    )

    return SocketMessage.ToolCallWrapper(
      toolCallID: toolCall.id,
      kind: .detectedFood(detectedFood)
    )
  }

  func logWater(toolCall: Run.ToolCall) async throws -> SocketMessage.ToolCallWrapper {
    guard toolCall.function.name == .Function.logWater else {
      throw Abort(.internalServerError, reason: "Improper tool handling")
    }

    let arguments = try toolCall.decodeArguments(type: SocketMessage.LogWaterConsumption.self, using: decoder)

    return SocketMessage.ToolCallWrapper(
      toolCallID: toolCall.id,
      kind: .logWater(arguments)
    )
  }

  func logWeight(toolCall: Run.ToolCall) async throws -> SocketMessage.ToolCallWrapper {
    guard toolCall.function.name == .Function.logWeight else {
      throw Abort(.internalServerError, reason: "Improper tool handling")
    }

    let arguments = try toolCall.decodeArguments(type: SocketMessage.LogWeight.self, using: decoder)

    return SocketMessage.ToolCallWrapper(
      toolCallID: toolCall.id,
      kind: .logWeight(arguments)
    )
  }

  func logBloodPressure(toolCall: Run.ToolCall) async throws -> SocketMessage.ToolCallWrapper {
    guard toolCall.function.name == .Function.logBloodPressure else {
      throw Abort(.internalServerError, reason: "Improper tool handling")
    }

    let arguments = try toolCall.decodeArguments(type: SocketMessage.LogBloodPressure.self, using: decoder)

    return SocketMessage.ToolCallWrapper(
      toolCallID: toolCall.id,
      kind: .logBloodPressure(arguments)
    )
  }

  func logBowelMovements(toolCall: Run.ToolCall) async throws -> SocketMessage.ToolCallWrapper {
    guard toolCall.function.name == .Function.logBowelMovement else {
      throw Abort(.internalServerError, reason: "Improper tool handling")
    }

    let arguments = try toolCall.decodeArguments(type: SocketMessage.LogBowelMovement.self, using: decoder)

    return SocketMessage.ToolCallWrapper(
      toolCallID: toolCall.id,
      kind: .logBowelMovement(arguments)
    )
  }

  func createWorkout(toolCall: Run.ToolCall) async throws -> SocketMessage.ToolCallWrapper {
    guard toolCall.function.name == .Function.createWorkoutPlan else {
      throw Abort(.internalServerError, reason: "Improper tool handling")
    }

    let arguments = try toolCall.decodeArguments(type: SocketMessage.WorkoutPlan.self, using: decoder)

    return SocketMessage.ToolCallWrapper(
      toolCallID: toolCall.id,
      kind: .createWorkout(arguments)
    )
  }
}
