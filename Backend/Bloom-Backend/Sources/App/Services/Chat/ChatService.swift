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
    } else if let queryRequest = try? decoder.decode(SocketMessage.DataQueryRequest.self, from: data) {
      try await onDataQuery(queryRequest: queryRequest, userID: userID, db: db)
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

  func onDataQuery(
    queryRequest: SocketMessage.DataQueryRequest,
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

    let toolOutputs = queryRequest.queryData.map { ToolOutput(toolCallID: $0.id, output: $0.data) }

    let run = try await assistantService.submitSuccessfulToolOputput(
      threadID: thread.threadID,
      runID: queryRequest.id,
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

  func sendDataQueryResponse(
    run: Run,
    queries: [SocketMessage.Query],
    userID: UserIdentifier,
    db: any Database
  ) async throws {
    let dataQueryResponse = SocketMessage.DataQueryResponse(
      id: run.id,
      queries: queries
    )
    try await ensureContentSilentlySent(dataQueryResponse, userID: userID, db: db)
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
        Assistant.Tool.function(.queryUserHealthMetrics)
      ],
      existingRun: existingRun
    )

    switch assistantResponse {
    case .requiresAction(let run, let toolCalls):
      var queries = [SocketMessage.Query]()
      for toolCall in toolCalls {
        switch toolCall.function.name {
        case .Function.queryUserHealthData, .Function.queryUserHealthMetrics:
          let query = try await performQuery(toolCall: toolCall)
          queries.append(query)
        default:
          throw Abort(.internalServerError, reason: "Unsupported tool function: \(toolCall.function.name)")
        }
      }
      try await sendDataQueryResponse(run: run, queries: queries, userID: userID, db: db)
    case .messages(_, let messages):
      let response = messages
        .flatMap { message in
          message.content.compactMap({ $0.text?.data(using: .utf8) })
        }
        .compactMap { (data) -> ChatAssistantResponse? in
          do {
            return try JSONDecoder.bloomModel.decode(ChatAssistantResponse.self, from: data)
          } catch {
            logger.report(error: error)
            return nil
          }
        }
        .map { (response) -> SocketMessage.MessageResponse in
          let detectedFood: SocketMessage.DetectedFood?
          if let responseFood = response.detectedFood {
            detectedFood = SocketMessage.DetectedFood(
              name: responseFood.name,
              foodItemServings: responseFood.foodItems.map { $0.asServing() }
            )
          } else {
            detectedFood = nil
          }
          
          return SocketMessage.MessageResponse(
            message: response.message,
            healthMetricGoals: response.healthMetricGoals,
            detectedFood: detectedFood,
            logWaterConsumption: response.logWaterConsumption,
            logBowelMovement: response.logBowelMovement,
            logWeight: response.logWeight,
            logBloodPressure: response.logBloodPressure
          )
        }
        .first
      
      guard let response else {
        throw Abort(.internalServerError, reason: "Could not decode message from Assistant.")
      }
      
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

  func performQuery(toolCall: Run.ToolCall) async throws -> SocketMessage.Query {
    switch toolCall.function.name {
    case .Function.queryUserHealthData:
      let queryArguments = try toolCall.decodeArguments(type: QueryUserHealthDataArguments.self, using: decoder)
      return SocketMessage.Query(
        id: toolCall.id,
        startDate: queryArguments.startDate,
        endDate: queryArguments.endDate,
        dataType: queryArguments.dataType,
        healthMetric: nil
      )
    case .Function.queryUserHealthMetrics:
      let queryArguments = try toolCall.decodeArguments(type: QueryUserHealthMetricsArguments.self, using: decoder)
      return SocketMessage.Query(
        id: toolCall.id,
        startDate: queryArguments.startDate,
        endDate: queryArguments.endDate,
        dataType: nil,
        healthMetric: queryArguments.healthMetric
      )
    default:
      throw Abort(.internalServerError, reason: "Improper tool handling")
    }
  }
}
