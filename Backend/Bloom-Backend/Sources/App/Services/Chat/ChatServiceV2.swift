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

  private let modelID = ModelID.OSeries.o4Mini

  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel

  private let jsonBuffer = StreamJSONBuffer()
  private let typingStateTracker = TypingStateTracker()
  private let requestIDTracker = RequestIDTracker()
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

  func uploadImages(imageData: [Data]) async throws -> [String] {
    try await withThrowingTaskGroup(of: String.self) { [openAIService] group in
      for image in imageData {
        group.addTask {
          let file = try await openAIService.openAI.files.upload(file: image, purpose: .userData)
          return file.id
        }
      }

      var fileIDs = [String]()
      for try await fileID in group {
        fileIDs.append(fileID)
      }
      return fileIDs
    }
  }

  func flushCachedStreamingContent(userID: UserIdentifier) async throws {
    let messages = try await chatHistory.flushCachedStreamingContent(userID: userID)
    
    guard !messages.isEmpty else { return }
    
    logger.debug("Flushing \(messages.count) cached messages for user \(userID)")
    
    // Send all cached messages
    for message in messages {
      if let messageChunk = message.messageChunk {
        _ = try await sendSocketContentIfAvailable(messageChunk, userID: userID)
      } else if let richMessage = message.richMessage {
        _ = try await sendSocketContentIfAvailable(richMessage, userID: userID)
      }
    }
  }
}

// MARK: - Incoming Message Handlers

private extension ChatServiceV2 {

  func on(
    message: SocketMessage.MessageRequest,
    userID: UserIdentifier,
    db: any Database
  ) async throws {

    // Store the requestID for this user's conversation
    await requestIDTracker.setCurrentRequestID(message.requestID, for: userID)

    var inputs = [OpenAIKit.Response.InputItem]()

    // System Messages
    inputs.append(
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

    inputs.append(.message(.init(role: .user, content: userContent)))

    // Cache inputs
//    try await chatHistory.append(userID: userID, inputItems: inputs)
    try await streamResponse(
      inputs: inputs,
      userID: userID,
      db: db
    )
  }

  func onToolCallsResponse(
    response: SocketMessage.ToolCallsResponse,
    userID: UserIdentifier,
    db: any Database
  ) async throws {

    // Update the requestID if provided in the response
    if let requestID = response.requestID {
      await requestIDTracker.setCurrentRequestID(requestID, for: userID)
    }

    let inputs = response.toolCallResults.map {
      let output = Response.InputItem.FunctionToolCallOutput(callId: $0.toolCallID, output: $0.data)
      return OpenAIKit.Response.InputItem.item(.functionToolCallOutput(output))
    }

    // Remove function calls
    for toolCallResult in response.toolCallResults {
      try await chatHistory.removeFunctionCallID(toolCallResult.toolCallID, for: userID)
    }

    // Cache inputs
//    try await chatHistory.append(userID: userID, inputItems: inputs)
    try await streamResponse(
      inputs: inputs,
      userID: userID,
      db: db
    )
  }
}

// MARK: - Stream Management

private extension ChatServiceV2 {

  func streamResponse(
    inputs: [OpenAIKit.Response.InputItem],
    userID: UserIdentifier,
    db: any Database,
    isRetry: Bool = false
  ) async throws {

    if isRetry {
      logger.info("Chat stream request failed, retrying once.")
    }

    let previousResponseID = try await chatHistory.getLastResponseID(for: userID)
    let fortifiedInputs = try await fortify(inputs: inputs, userID: userID)

    let stream = try await openAIService.openAI.responses.createAndStreamResponse(
      input: fortifiedInputs,
      model: modelID,
      instructions: .Prompt.chatAssistant,
      previousResponseID: previousResponseID,
      reasoning: .init(effort: .low, summary: .detailed),
      tools: [
        Response.Tool.function(.queryUserHealthData),
        Response.Tool.function(.createUserFact),
        Response.Tool.function(.deleteUserFact)
      ],
      user: userID.value
    )

    var toolCalls = [OpenAIKit.Response.OutputItem.FunctionToolCall]()

    func performRetry() async throws {
      guard !isRetry else { return }

      try await chatHistory.clearLastResponseID(for: userID)
      try await chatHistory.clearFunctionCallIDs(for: userID)

      try await streamResponse(
        inputs: inputs,
        userID: userID,
        db: db,
        isRetry: true
      )
    }

    for try await event in stream {
      do {
        switch event {
        case .created:
          await jsonBuffer.resetIndex(for: userID)
          await typingStateTracker.reset(for: userID)
        case .inProgress:
          try await sendIsAssistantTyping(isTyping: true, userID: userID)
        case .completed(let event):
          if toolCalls.isNotEmpty {
            try await send(toolCalls: toolCalls, userID: userID, db: db)
          }

          try await chatHistory.storeLastResponseID(event.response.id, for: userID)
          try await sendIsAssistantTyping(isTyping: false, userID: userID)
          if toolCalls.isEmpty {
            try await sendResponseCompleted(userID: userID, db: db)
          }
        case .failed:
          try await sendIsAssistantTyping(isTyping: false, userID: userID)
          try await performRetry()
        case .outputTextDelta(let event):
          try await bufferChunk(event: event, userID: userID, db: db)
        case .outputTextDone(let event):
          try await sendCompletedMessage(event: event, userID: userID, db: db)
        case .outputItemDone(let event):
          switch event.item {
          case .functionToolCall(let call):
            toolCalls.append(call)
            try await chatHistory.storeFunctionCallID(call.callId, for: userID)
          case .reasoning(let reasoning):
            for summary in reasoning.summary {
              logger.debug("Reasoning: \(summary.text)")
            }
          default:
            break
          }
        case .error(let event):
          print(event.error)
          try await sendIsAssistantTyping(isTyping: false, userID: userID)
          try await performRetry()
        default:
          logger.debug("\(event)")
          break
        }
      } catch {
        logger.error("\(error)")
      }
    }
  }

  func fortify(
    inputs: [OpenAIKit.Response.InputItem],
    userID: UserIdentifier
  ) async throws -> [OpenAIKit.Response.InputItem] {
    // Check for any pending function calls and inject error outputs
    let pendingCallIDs = try await chatHistory.getFunctionCallIDs(for: userID)
    var modifiedInputs = inputs

    for callID in pendingCallIDs {
      let errorOutput = Response.InputItem.FunctionToolCallOutput(
        callId: callID,
        output: "There was an error running this tool"
      )
      modifiedInputs.append(.item(.functionToolCallOutput(errorOutput)))

      // Remove the function call ID since we're handling it
      try await chatHistory.removeFunctionCallID(callID, for: userID)
    }
    return modifiedInputs
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
    let currentRequestID = await requestIDTracker.getCurrentRequestID(for: userID)

    for data in filteredData {
      switch data {
      case .chunk(let index, let chunk):
        // Turn off typing indicator when we start streaming text chunks
        try await sendIsAssistantTyping(isTyping: false, userID: userID)
        
        let messageChunk = SocketMessage.MessageChunkResponse(
          id: event.itemId + "-\(index)", 
          chunk: chunk,
          requestID: currentRequestID
        )
        let wasSent = try await sendSocketContentIfAvailable(messageChunk, userID: userID)
        if !wasSent {
          try await chatHistory.cacheStreamingContent(messageChunk, userID: userID)
        }
      case .json(let index, let json):
        let kind = try parseKind(from: json)

        let message = SocketMessage.RichMessageResponse(
          id: event.itemId + "-\(index)", 
          kind: kind, 
          isTemporary: true,
          requestID: currentRequestID
        )
        let wasSent = try await sendSocketContentIfAvailable(message, userID: userID)
        if !wasSent {
          try await chatHistory.cacheStreamingContent(message, userID: userID)
        }

      case .collectingJSON:
        try await sendIsAssistantTyping(isTyping: true, userID: userID)
      case .streamingText:
        try await sendIsAssistantTyping(isTyping: false, userID: userID)
      }
    }
  }

  func sendCompletedMessage(
    event: OpenAIKit.Response.OutputTextDoneEvent,
    userID: UserIdentifier,
    db: any Database
  ) async throws {
    try await chatHistory.append(userID: userID, inputItems: [.itemReference(.init(id: event.itemId))])

    let partitions = await jsonBuffer.processCompletedMessage(event.text, for: userID)
    let currentRequestID = await requestIDTracker.getCurrentRequestID(for: userID)

    for partition in partitions {
      switch partition {
      case .text(let index, let content):
        logger.trace("Assistant Message: \(content)")
        let response = SocketMessage.MessageResponse(
          id: event.itemId + "-\(index)", 
          message: content,
          requestID: currentRequestID
        )
        try await ensureContentSent(
          response,
          title: "Bud",
          message: content.truncated(to: 200),
          userID: userID,
          db: db
        )
      case .json(let index, let content):
        let kind = try parseKind(from: content)

        logger.trace("Assistant Rich Content: \(content)")

        let response = SocketMessage.RichMessageResponse(
          id: event.itemId + "-\(index)",
          kind: kind,
          isTemporary: false,
          requestID: currentRequestID
        )
        try await ensureContentSilentlySent(response, userID: userID, db: db)
      }
    }
    
    // Clear any cached streaming content since this message is now complete
    try await chatHistory.clearStreamingContent(userID: userID)
  }

  func parseKind(from json: String) throws -> SocketMessage.RichMessageResponse.Kind {
    let trimmedJSON = json.trimmingCharacters(in: .whitespacesAndNewlines)
    let data = trimmedJSON.data(using: .utf8) ?? Data()

    if let kind = handleNewGoals(data: data) {
      return kind
    }
    if let kind = handleLogFood(data: data) {
      return kind
    }
    if let kind = handleLogWater(data: data) {
      return kind
    }
    if let kind = handleLogWeight(data: data) {
      return kind
    }
    if let kind = handleLogPeriod(data: data) {
      return kind
    }
    if let kind = handleLogBloodPressure(data: data) {
      return kind
    }
    if let kind = handleLogBowelMovements(data: data) {
      return kind
    }
    if let kind = handleCreateWorkout(data: data) {
      return kind
    }
    if let kind = handleCreateReminder(data: data) {
      return kind
    }

    logger.error("Could not parse JSON as Rich Message:\n\(json)\n")
    return .invalid(json)
  }

  func handleNewGoals(data: Data) -> SocketMessage.RichMessageResponse.Kind? {
    guard let arguments = try? decoder.decode(SetGoalsArguments.self, from: data) else {
      return nil
    }
    return .newGoals(arguments.newGoals)
  }

  func handleLogFood(data: Data) -> SocketMessage.RichMessageResponse.Kind? {
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

  func handleLogWater(data: Data) -> SocketMessage.RichMessageResponse.Kind? {
    if let content = try? decoder.decode(SocketMessage.LogWaterConsumption.self, from: data) {
      return .logWater(content)
    }
    return nil
  }

  func handleLogWeight(data: Data) -> SocketMessage.RichMessageResponse.Kind? {
    if let content = try? decoder.decode(SocketMessage.LogWeight.self, from: data) {
      return .logWeight(content)
    }
    return nil
  }

  func handleLogPeriod(data: Data) -> SocketMessage.RichMessageResponse.Kind? {
    if let content = try? decoder.decode(SocketMessage.LogPeriod.self, from: data) {
      return .logPeriod(content)
    }
    return nil
  }

  func handleLogBloodPressure(data: Data) -> SocketMessage.RichMessageResponse.Kind? {
    if let content = try? decoder.decode(SocketMessage.LogBloodPressure.self, from: data) {
      return .logBloodPressure(content)
    }
    return nil
  }

  func handleLogBowelMovements(data: Data) -> SocketMessage.RichMessageResponse.Kind? {
    if let content = try? decoder.decode(SocketMessage.LogBowelMovement.self, from: data) {
      return .logBowelMovement(content)
    }
    return nil
  }

  func handleCreateWorkout(data: Data) -> SocketMessage.RichMessageResponse.Kind? {
    if let content =  try? decoder.decode(SocketMessage.WorkoutPlan.self, from: data) {
      return .createWorkout(content)
    }
    return nil
  }

  func handleCreateReminder(data: Data) -> SocketMessage.RichMessageResponse.Kind? {
    if let content = try? decoder.decode(SocketMessage.CreateReminder.self, from: data) {
      return .createReminder(content)
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
      case .Function.createUserFact:
        toolCallWrappers.append(try await createUserFact(toolCall: toolCall))
      case .Function.deleteUserFact:
        toolCallWrappers.append(try await deleteUserFact(toolCall: toolCall))
      default:
        throw Abort(.internalServerError, reason: "Unsupported tool function: \(toolCall.name)")
      }
    }

    let currentRequestID = await requestIDTracker.getCurrentRequestID(for: userID)
    let toolCallRequest = SocketMessage.ToolCallsRequest(
      runID: "",
      toolCalls: toolCallWrappers,
      requestID: currentRequestID
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

  func createUserFact(
    toolCall: OpenAIKit.Response.OutputItem.FunctionToolCall
  ) async throws -> SocketMessage.ToolCallWrapper {
    guard toolCall.name == .Function.createUserFact else {
      throw Abort(.internalServerError, reason: "Improper tool handling")
    }

    let arguments = try toolCall.decodeArguments(type: SocketMessage.CreateUserFact.self, using: decoder)

    return SocketMessage.ToolCallWrapper(toolCallID: toolCall.callId, kind: .createUserFact(arguments))
  }

  func deleteUserFact(
    toolCall: OpenAIKit.Response.OutputItem.FunctionToolCall
  ) async throws -> SocketMessage.ToolCallWrapper {
    guard toolCall.name == .Function.deleteUserFact else {
      throw Abort(.internalServerError, reason: "Improper tool handling")
    }

    let arguments = try toolCall.decodeArguments(type: SocketMessage.DeleteUserFact.self, using: decoder)

    return SocketMessage.ToolCallWrapper(toolCallID: toolCall.callId, kind: .deleteUserFact(arguments))
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
  ) async throws -> Bool where Content: Encodable {
    guard let socket = await socket(for: userID) else {
      return false
    }
    try socket.sendContent(content)
    return true
  }

  func sendIsAssistantTyping(
    isTyping: Bool,
    userID: UserIdentifier
  ) async throws {
    // Only send if the state actually changed
    let stateChanged = await typingStateTracker.setTypingIfChanged(isTyping, for: userID)
    if stateChanged {
      let typingIndicator = SocketMessage.TypingIndicator(isTyping: isTyping)
      _ = try await sendSocketContentIfAvailable(typingIndicator, userID: userID)
    }
  }

  func sendResponseCompleted(userID: UserIdentifier, db: any Database) async throws {
    let currentRequestID = await requestIDTracker.getCurrentRequestID(for: userID)
    let responseCompleted = SocketMessage.ResponseCompleted(requestID: currentRequestID)
    try await ensureContentSilentlySent(responseCompleted, userID: userID, db: db)
    
    // Clear the requestID after the response is completed
    await requestIDTracker.clearRequestID(for: userID)
  }

  func ensureContentSent<Content>(
    _ content: Content,
    title: String,
    message: String,
    userID: UserIdentifier,
    db: any Database
  ) async throws where Content: Encodable, Content: Sendable {
    logger.debug("ensureContentSent")

    if let socket = await socket(for: userID) {
      try socket.sendContent(content)
      return
    }

    logger.debug("Could not send over web socket. Attempting APNs.")

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
      logger.debug("Could not relay message to user \(userID). No Device Token set.")
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
    logger.debug("ensureContentSilentlySent")

    if let socket = await socket(for: userID) {
      try socket.sendContent(content)
      return
    }

    logger.debug("Could not send over web socket. Attempting APNs.")

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
      logger.debug("Could not relay silent message to user \(userID). No Device Token set.")

      // TODO: Store in redis? Or cancel run?
    }
  }
}
