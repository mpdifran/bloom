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

// MARK: - WebSocket Helpers

private extension ChatService {

  func sendSocketContentIfAvailable<Content>(
    _ content: Content,
    userID: UserIdentifier
  ) async throws where Content: Encodable {
    let webSocketService = application.webSocketService

    guard let socket = await webSocketService.webSocket(for: userID) else {
      return
    }

    try socket.sendContent(content)
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
    userID: UserIdentifier
  ) async throws {
    let dataQueryResponse = SocketMessage.DataQueryResponse(
      id: run.id,
      queries: queries
    )
    try await sendSocketContentIfAvailable(dataQueryResponse, userID: userID)
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
//      toolChoice: .function(.Function.queryUserHealthMetrics),
      existingRun: existingRun
    )

    switch assistantResponse {
    case .requiresAction(let run, let toolCalls):
      var queries = [SocketMessage.Query]()
      for toolCall in toolCalls {
        switch toolCall.function.name {
        case .Function.queryUserHealthData:
          let queryArguments = try toolCall.decodeArguments(type: QueryUserHealthDataArguments.self, using: decoder)
          let query = SocketMessage.Query(
            id: toolCall.id,
            startDate: queryArguments.startDate,
            endDate: queryArguments.endDate,
            dataType: queryArguments.dataType,
            healthMetric: nil
          )
          queries.append(query)
        case .Function.queryUserHealthMetrics:
          let queryArguments = try toolCall.decodeArguments(type: QueryUserHealthMetricsArguments.self, using: decoder)
          let query = SocketMessage.Query(
            id: toolCall.id,
            startDate: queryArguments.startDate,
            endDate: queryArguments.endDate,
            dataType: nil,
            healthMetric: queryArguments.healthMetric
          )
          queries.append(query)
        default:
          throw Abort(.internalServerError, reason: "Unsupported tool function: \(toolCall.function.name)")
        }
      }
      try await sendDataQueryResponse(run: run, queries: queries, userID: userID)
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

      try await sendSocketContentIfAvailable(response, userID: userID) // TODO: Send push notification if no socket.
    }
  }
}
