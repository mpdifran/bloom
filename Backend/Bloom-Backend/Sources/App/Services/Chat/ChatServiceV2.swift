//
//  ChatServiceV2.swift
//  Bloom-Backend
//
//  Created by Mark DiFranco on 2025-05-20.
//

import Foundation
import Vapor
import BloomModel
import OpenAIKit
import Fluent
import APNS
import APNSCore
import Redis

// MARK: - ChatServiceV2

final class ChatServiceV2: Sendable {

  private let application: Application
  private let openAIService: OpenAIService
  private let chatHistory: ChatHistory
  private let logger: Logger

  init(
    application: Application,
    logger: Logger
  ) {
    self.application = application
    self.openAIService = application.openAIService
    self.chatHistory = application.chatHistory
    self.logger = logger
  }

  private let modelID = ModelID.GPT4.gpt_4o_mini

  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel

  private let jsonBuffer = StreamJSONBuffer()
}

// MARK: - Public Methods

extension ChatServiceV2 {

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

private extension ChatServiceV2 {

  func on(
    message: SocketMessage.MessageRequest,
    userID: UserIdentifier,
    db: any Database
  ) async throws {

    var input = [OpenAIKit.Response.InputItem]()

    // System Messages
    input.append(
      .message(
        .init(
          role: .system,
          content: [
            .text(.init(text: "Here are some details about the user's current preferences:\n\(message.userInfo)"))
          ]
        )
      )
    )

    // User Messages
    var userContent = [OpenAIKit.Response.InputItem.Content]()
    for fileID in message.imageFileIDs {
      userContent.append(.image(.init(detail: .auto, fileId: fileID)))
    }
    if message.text.isNotEmpty {
      userContent.append(.text(.init(text: message.text)))
    }

    guard userContent.isNotEmpty else { return }

    input.append(.message(.init(role: .user, content: userContent)))

    // Cache inputs
    try await chatHistory.append(userID: userID, inputItems: input)
    try await streamResponse(userID: userID, db: db)
  }

  func onToolCallsResponse(
    response: SocketMessage.ToolCallsResponse,
    userID: UserIdentifier,
    db: any Database
  ) async throws {

    let inputs = response.toolCallResults.map {
      let output = Response.InputItem.FunctionToolCallOutput(callId: $0.toolCallID, output: $0.data)
      return OpenAIKit.Response.InputItem.item(.functionToolCallOutput(output))
    }

    // Cache inputs
    try await chatHistory.append(userID: userID, inputItems: inputs)
    try await streamResponse(userID: userID, db: db)
  }
}

// MARK: - Stream Management

private extension ChatServiceV2 {

  func streamResponse(
    userID: UserIdentifier,
    db: any Database
  ) async throws {

    let inputHistory = try await chatHistory.load(for: userID)

    let stream = try await openAIService.openAI.responses.createAndStreamResponse(
      input: inputHistory,
      model: modelID,
      instructions: .Prompt.chatAssistant,
      tools: [Response.Tool.function(.queryUserHealthData)],
      user: userID.value
    )

    var toolCalls = [OpenAIKit.Response.OutputItem.FunctionToolCall]()

    for try await event in stream {
//      print("[TRACE] \(event)")
      do {
        switch event {
        case .inProgress:
          try await sendIsAssistantTyping(isTyping: true, userID: userID)
        case .completed:
          if toolCalls.isNotEmpty {
            try await send(toolCalls: toolCalls, userID: userID, db: db)
          }

          try await sendIsAssistantTyping(isTyping: false, userID: userID)
        case .failed:
          try await sendIsAssistantTyping(isTyping: false, userID: userID)
        case .outputTextDelta(let event):
          try await bufferChunk(event: event, userID: userID, db: db)
        case .outputTextDone(let event):
          try await sendCompletedMessage(event: event, userID: userID, db: db)
        case .outputItemDone(let event):
          switch event.item {
          case .functionToolCall(let call):
            toolCalls.append(call)
          default:
            break
          }
        case .error(let event):
          print(event.error)
        default:
          break
//          print("[TRACE] \(event)")
        }
      } catch {
        print("[TRACE] \(error)")
      }
    }
  }
}

// MARK: - Streaming Chunk Buffering

private extension ChatServiceV2 {

  func bufferChunk(
    event: OpenAIKit.Response.OutputTextDeltaEvent,
    userID: UserIdentifier,
    db: any Database
  ) async throws {
    let filteredData = await jsonBuffer.filter(event.delta, for: userID)

    switch filteredData {
    case .chunk(let chunk):
      let messageChunk = SocketMessage.MessageChunkResponse(id: event.itemId, chunk: chunk)
      try await sendSocketContentIfAvailable(messageChunk, userID: userID)
    case .json(let json):
      guard let kind = try parseKind(from: json) else { return }

      let message = SocketMessage.RichMessageResponse(id: event.itemId, kind: kind, isTemporary: true)
      try await ensureContentSilentlySent(message, userID: userID, db: db)
    }
  }

  func sendCompletedMessage(
    event: OpenAIKit.Response.OutputTextDoneEvent,
    userID: UserIdentifier,
    db: any Database
  ) async throws {
    try await chatHistory.append(userID: userID, inputItems: [.itemReference(.init(id: event.itemId))])

    let partitions = await jsonBuffer.processCompletedMessage(event.text, for: userID)

    for partition in partitions {
      switch partition {
      case .text(let index, let content):
        logger.trace("Assistant Message: \(content)")
        let response = SocketMessage.MessageResponse(id: event.itemId + "-\(index)", message: content)
        try await ensureContentSent(
          response,
          title: "Bud",
          message: event.text,
          userID: userID,
          db: db
        )
      case .json(let index, let content):
        guard let kind = try parseKind(from: content) else { continue }

        logger.trace("Assistant Rich Content: \(content)")

        let response = SocketMessage.RichMessageResponse(
          id: event.itemId + "-\(index)",
          kind: kind,
          isTemporary: false
        )
        try await ensureContentSilentlySent(response, userID: userID, db: db)
      }
    }
  }

  func parseKind(from json: String) throws -> SocketMessage.RichMessageResponse.Kind? {
    let data = json.data(using: .utf8) ?? Data()

    if let kind = try handleNewGoals(data: data) {
      return kind
    }
    if let kind = try handleLogFood(data: data) {
      return kind
    }
    if let kind = try handleLogWater(data: data) {
      return kind
    }
    if let kind = try handleLogWeight(data: data) {
      return kind
    }
    if let kind = try handleLogPeriod(data: data) {
      return kind
    }
    if let kind = try handleLogBloodPressure(data: data) {
      return kind
    }
    if let kind = try handleLogBowelMovements(data: data) {
      return kind
    }
    if let kind = try handleCreateWorkout(data: data) {
      return kind
    }

    logger.error("Could not parse JSON as Rich Message:\n\n\(json)\n\n")
    return nil
  }

  func handleNewGoals(
    data: Data
  ) throws -> SocketMessage.RichMessageResponse.Kind? {
    guard let arguments = try? decoder.decode(SetGoalsArguments.self, from: data) else {
      return nil
    }
    return .newGoals(arguments.newGoals)
  }

  func handleLogFood(data: Data) throws -> SocketMessage.RichMessageResponse.Kind? {
    guard let arguments = try? decoder.decode(DetectedFood.self, from: data) else {
      return nil
    }

    let food = SocketMessage.DetectedFood(
      name: arguments.name,
      meal: arguments.meal,
      foodItemServings: arguments.foodItems.map { $0.asServing() }
    )

    return .detectedFood(food)
  }

  func handleLogWater(data: Data) throws -> SocketMessage.RichMessageResponse.Kind? {
    if let content = try? decoder.decode(SocketMessage.LogWaterConsumption.self, from: data) {
      return .logWater(content)
    }
    return nil
  }

  func handleLogWeight(data: Data) throws -> SocketMessage.RichMessageResponse.Kind? {
    if let content = try? decoder.decode(SocketMessage.LogWeight.self, from: data) {
      return .logWeight(content)
    }
    return nil
  }

  func handleLogPeriod(data: Data) throws -> SocketMessage.RichMessageResponse.Kind? {
    if let content = try? decoder.decode(SocketMessage.LogPeriod.self, from: data) {
      return .logPeriod(content)
    }
    return nil
  }

  func handleLogBloodPressure(data: Data) throws -> SocketMessage.RichMessageResponse.Kind? {
    if let content = try? decoder.decode(SocketMessage.LogBloodPressure.self, from: data) {
      return .logBloodPressure(content)
    }
    return nil
  }

  func handleLogBowelMovements(data: Data) throws -> SocketMessage.RichMessageResponse.Kind? {
    if let content = try? decoder.decode(SocketMessage.LogBowelMovement.self, from: data) {
      return .logBowelMovement(content)
    }
    return nil
  }

  func handleCreateWorkout(data: Data) throws -> SocketMessage.RichMessageResponse.Kind? {
    if let content =  try? decoder.decode(SocketMessage.WorkoutPlan.self, from: data) {
      return .createWorkout(content)
    }
    return nil
  }
}

// MARK: - Tool Calls

private extension ChatServiceV2 {

  func send(
    toolCalls: [OpenAIKit.Response.OutputItem.FunctionToolCall],
    userID: UserIdentifier,
    db: any Database
  ) async throws {

    // Cache the tool call
    let inputItems = toolCalls.map {
      OpenAIKit.Response.InputItem.item(.functionToolCall($0))
    }
    try await chatHistory.append(userID: userID, inputItems: inputItems)

    var toolCallWrappers = [SocketMessage.ToolCallWrapper]()

    for toolCall in toolCalls {
      switch toolCall.name {
      case .Function.queryUserHealthData:
        toolCallWrappers.append(try await performQuery(toolCall: toolCall))
      default:
        throw Abort(.internalServerError, reason: "Unsupported tool function: \(toolCall.name)")
      }
    }

    let toolCallRequest = SocketMessage.ToolCallsRequest(
      runID: "",
      toolCalls: toolCallWrappers
    )
    try await ensureContentSilentlySent(toolCallRequest, userID: userID, db: db)
  }

  func performQuery(
    toolCall: OpenAIKit.Response.OutputItem.FunctionToolCall
  ) async throws -> SocketMessage.ToolCallWrapper {
    guard toolCall.name == .Function.queryUserHealthData else {
      throw Abort(.internalServerError, reason: "Improper tool handling")
    }

    let queryArguments = try toolCall.decodeArguments(type: QueryUserHealthDataArguments.self, using: decoder)

    let queries = queryArguments.queries.map { arguments in
      SocketMessage.Query(
        startDate: arguments.startDate,
        endDate: arguments.endDate,
        dataType: arguments.dataType
      )
    }

    return SocketMessage.ToolCallWrapper(toolCallID: toolCall.callId, kind: .queries(queries))
  }
}

// MARK: - Communication Methods

private extension ChatServiceV2 {

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
