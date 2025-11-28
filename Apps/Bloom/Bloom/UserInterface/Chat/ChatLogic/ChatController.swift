//
//  ChatController.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-21.
//

import SwiftUI
import DataContainer
import BloomModel
import BloomFoundation
import BloomUI
import SwiftData
import CoreHealth
import HealthKit
import TelemetryDeck
import CoreNetwork

extension ChatController {
  struct InProgressMessage: Identifiable, Hashable, Sendable {
    let id: String
    var message: String
    let data: Data?
    let conversationID: String

    init(id: String, message: String, conversationID: String) {
      self.id = id
      self.message = message
      self.data = nil
      self.conversationID = conversationID
    }

    init(id: String, data: Data, conversationID: String) {
      self.id = id
      self.message = ""
      self.data = data
      self.conversationID = conversationID
    }
  }
}

final actor ChatController: ObservableObject {
  static let shared = ChatController()

  @AsyncStreamable var assistantTypingStatus: [String: String?] = [:]
  @AsyncStreamable var assistantIsTyping: [String: Bool] = [:]
  @AsyncStreamable var inProgressMessages: [String: [InProgressMessage]] = [:]
  @AsyncStreamable var lastMessageIDUpdate: LastMessageIDUpdate?
  private var inProgressMessagesIndex: [String: Int] = [:]
  @AsyncStreamable var error: Error?
  @AsyncStreamable var conversationInProgress: [String: Bool] = [:]
  @AsyncStreamable var conversationIDToRefresh: String?

  @AppStorage(.FeatureFlag.enableOpenAIModelOverride) private var enableOpenAIModelOverride = false

  struct LastMessageIDUpdate: Equatable {
    let conversationID: String
    let lastMessageID: String
  }

  private init() { }

  private var queryAreas: [String: [String]] = [:] {
    didSet {
      for (conversationID, areas) in queryAreas {
        if areas.isEmpty {
          assistantTypingStatus[conversationID] = nil
        } else {
          if let listContent = listFormatter.string(from: areas) {
            assistantTypingStatus[conversationID] = "Reading \(listContent)..."
          } else {
            assistantTypingStatus[conversationID] = nil
          }
        }
      }
    }
  }

  private var webSocketHandle: WebSocketHandle?
  private var webSocketDataTask: Task<Void, Never>?
  private var webSocketDisconnectionTask: Task<Void, Never>?
  private var webSocketErrorTask: Task<Void, Never>?

  private var throttleTasks: [String: Task<Void, Never>] = [:]
  private let throttleInterval: UInt64 = 100_000_000  // 100 ms in nanoseconds
  private var lastEmitTimes: [String: UInt64] = [:]
  private var pendingInternalInProgressMessages: [String: [InProgressMessage]] = [:]
  private var internalInProgressMessages: [String: [InProgressMessage]] = [:] {
    didSet {
      for (conversationID, messages) in internalInProgressMessages {
        let now = DispatchTime.now().uptimeNanoseconds
        let lastEmitTime = lastEmitTimes[conversationID] ?? 0

        // If enough time has passed since last emit, send immediately
        if now - lastEmitTime >= throttleInterval {
          lastEmitTimes[conversationID] = now
          inProgressMessages[conversationID] = messages
        } else {
          // Buffer the latest value
          pendingInternalInProgressMessages[conversationID] = messages
          // Schedule a trailing emit if not already scheduled
          if throttleTasks[conversationID] == nil {
            // Calculate remaining wait time
            let wait = throttleInterval - (now - lastEmitTime)
            throttleTasks[conversationID] = Task { [conversationID] in
              // Sleep for the remainder of the interval
              try? await Task.sleep(nanoseconds: wait)
              // After interval, emit the buffered value if still present
              if let valueToEmit = pendingInternalInProgressMessages[conversationID] {
                lastEmitTimes[conversationID] = DispatchTime.now().uptimeNanoseconds
                inProgressMessages[conversationID] = valueToEmit
                pendingInternalInProgressMessages[conversationID] = nil
              }
              throttleTasks[conversationID] = nil
            }
          }
        }
      }
    }
  }

  private let listFormatter = ListFormatter()
  private let modelContext = ModelContext(ContainerHolder.shared.container)
  private let conversationActor = ConversationModelActor(modelContainer: ContainerHolder.shared.container)
  private let queryPerformer = ChatHealthQueryPerformer()

  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel
  
  private var currentRequestID: String?
  private var toolCallIDs = Set<String>()
  private var toolRequestCount = 0
}

extension ChatController {
  
  var isDisconnected: Bool {
    webSocketHandle == nil
  }
  
  func ensureWebSocketConnected() async {
    if webSocketHandle == nil {
      _ = await createOrGetWebSocketHandle()
    }
  }
  
  func reconnectWebSocket() async {
    // Clean up existing connection
    onDisconnection()
    
    // Create new connection
    _ = await createOrGetWebSocketHandle()
  }

  func send(message: String, image: UIImage?, chatContexts: [ChatContext], conversationID: String?, lastMessageID: String?) async throws {
    // Send any pending telemetry before starting a new message
    sendToolCallCountTelemetry()
    sendToolRequestCountTelemetry()

    // Create new conversation if needed
    let resolvedConversationID: String
    if let conversationID = conversationID {
      resolvedConversationID = conversationID
    } else {
      let conversation = try await conversationActor.createConversation(name: "Chat")
      resolvedConversationID = conversation.id
    }

    // Generate a new request ID
    let requestID = "request_\(UUID().uuidString)"
    currentRequestID = requestID

    // Fetch the conversation for message relationship
    let conversationModel = try getConversationModel(id: resolvedConversationID)

    let imageData = image?.resized(toWidth: 800)?.jpegData(compressionQuality: 0.75)
    let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

    if let imageData {
      let imageMessage = ChatMessage(
        isCurrentUser: true,
        imageData: imageData,
        requestID: requestID,
        conversation: conversationModel
      )
      try await saveMessage(imageMessage)
    }

    for chatContext in chatContexts {
      let contextData = try encoder.encode(chatContext)
      let contextMessage = ChatMessage(
        isCurrentUser: true,
        richContent: contextData,
        requestID: requestID,
        conversation: conversationModel
      )
      try await saveMessage(contextMessage)
    }

    if trimmedMessage.isNotEmpty {
      let userMessage = ChatMessage(
        isCurrentUser: true,
        message: message,
        requestID: requestID,
        conversation: conversationModel
      )
      try await saveMessage(userMessage)
    }

    let enabledCategories = await getEnabledCategories()
    let demographics = await ChatVitalConverter.shared.generateDemographics(enabledCategories: enabledCategories)
    let stringData = try encoder.encodeToString(demographics) ?? ""

    let fileIDs: [String]
    if let imageData {
      fileIDs = try await NetworkRequester.shared.uploadChatImages(images: [imageData]).fileIDs
    } else {
      fileIDs = []
    }

    guard trimmedMessage.isNotEmpty || fileIDs.isNotEmpty else { return }

    let extraSystemContext: String?
    if chatContexts.isNotEmpty {
      let chatContextTexts = chatContexts.reduce("", { partialResult, chatContext in
        partialResult + "\n\(chatContext.title): \(chatContext.context)"
      })
      extraSystemContext = "The user is asking a question about these insights from the Today View: \n\n\(chatContextTexts)"
    } else {
      extraSystemContext = nil
    }

    let socketMessage = SocketMessage.MessageRequest(
      text: trimmedMessage,
      imageFileIDs: fileIDs,
      userInfo: stringData,
      extraSystemContext: extraSystemContext,
      requestID: requestID,
      lastMessageID: lastMessageID,
      conversationID: resolvedConversationID
    )

    let socket = await createOrGetWebSocketHandle()
    try await socket.send(payload: socketMessage)

    conversationInProgress[resolvedConversationID] = true

    await SoundPlayer.playSendMessage()

    TelemetryDeck.signal(
      "Send Chat Message",
      parameters: [
        "includesChatImages": fileIDs.isNotEmpty ? "Yes" : "No"
      ]
    )

    await TelemetryDeck.startDurationSignal("Chat TTFT")
    await TelemetryDeck.startDurationSignal("Chat TTFTC")
  }

  func sendSystemContextMessage(dummyAssistantMessage: String?, systemContext: String, conversationID: String?, lastMessageID: String?) async throws {
    // Create new conversation if needed
    let resolvedConversationID: String
    if let conversationID = conversationID {
      resolvedConversationID = conversationID
    } else {
      let conversation = try await conversationActor.createConversation(name: "Chat")
      resolvedConversationID = conversation.id
    }

    // Generate a new request ID
    let requestID = "request_\(UUID().uuidString)"
    currentRequestID = requestID

    // Fetch the conversation for message relationship
    let conversationModel = try getConversationModel(id: resolvedConversationID)

    if let dummyAssistantMessage {
      let assistantMessage = ChatMessage(
        isCurrentUser: false,
        message: dummyAssistantMessage,
        requestID: requestID,
        conversation: conversationModel
      )
      try await saveMessage(assistantMessage)
    }

    let enabledCategories = await getEnabledCategories()
    let demographics = await ChatVitalConverter.shared.generateDemographics(enabledCategories: enabledCategories)
    let stringData = try encoder.encodeToString(demographics) ?? ""

    let socketMessage = SocketMessage.MessageRequest(
      text: "",
      imageFileIDs: [],
      userInfo: stringData,
      extraSystemContext: systemContext,
      requestID: requestID,
      lastMessageID: lastMessageID,
      conversationID: resolvedConversationID
    )

    let socket = await createOrGetWebSocketHandle()
    try await socket.send(payload: socketMessage)
  }

  func handlePushData(_ data: Data) async {
    await parse(data: data)
  }
}

private extension ChatController {

  // MARK: - WebSocket Management

  func createOrGetWebSocketHandle() async -> WebSocketHandle {
    if let existingHandle = webSocketHandle {
      return existingHandle
    }

    let modelOverride = enableOpenAIModelOverride ? "o3" : nil
    let handle = await NetworkRequester.shared.openChatWebsocket(modelOverride: modelOverride)

    webSocketDataTask = Task.detached { [weak self] in
      for await data in await handle.$data {
        if let data {
          await self?.parse(data: data)
        }
      }
    }
    webSocketDisconnectionTask = Task.detached { [weak self] in
      for await isDisconnected in await handle.$hasDisconnected {
        if isDisconnected {
          await self?.onDisconnection()
        }
      }
    }
    webSocketErrorTask = Task.detached {
      for await error in await handle.$error {
        if let error {
          print(error)
//          await self?.on(error: error)
        }
      }
    }

    webSocketHandle = handle
    return handle
  }

  func parse(data: Data) async {
    if let messageResponse = try? decoder.decode(SocketMessage.MessageResponse.self, from: data) {
      let trimmedMessage = messageResponse.message.trimmingCharacters(in: .whitespacesAndNewlines)

      guard trimmedMessage.isNotEmpty else {
        return
      }

      guard let conversationID = messageResponse.conversationID else {
        print("Warning: MessageResponse missing conversationID")
        return
      }

      do {
        let conversationModel = try getConversationModel(id: conversationID)
        let message = ChatMessage(
          id: messageResponse.id,
          isCurrentUser: false,
          message: messageResponse.message,
          responseID: messageResponse.responseID,
          requestID: messageResponse.requestID,
          conversation: conversationModel
        )
        try await saveMessage(message)

        TelemetryDeck.signal("Received Bud Text Message")
      } catch {
        self.error = error
      }

      self.inProgressMessagesIndex[conversationID] = 0
      self.internalInProgressMessages[conversationID] = []
      self.queryAreas[conversationID] = []
      self.assistantIsTyping[conversationID] = false

    } else if let messageChunk = try? decoder.decode(SocketMessage.MessageChunkResponse.self, from: data) {
      guard let conversationID = messageChunk.conversationID else {
        print("Warning: MessageChunkResponse missing conversationID")
        return
      }

      self.queryAreas[conversationID] = []

      let index = self.inProgressMessagesIndex[conversationID] ?? 0
      var messages = self.internalInProgressMessages[conversationID] ?? []

      if messages.count > index {
        messages[index].message += messageChunk.chunk
      } else {
        let inProgressMessage = InProgressMessage(id: messageChunk.id, message: messageChunk.chunk, conversationID: conversationID)
        messages.append(inProgressMessage)

        await TelemetryDeck.stopAndSendDurationSignal("Chat TTFT")
      }

      self.internalInProgressMessages[conversationID] = messages
    } else if let richContentMessage = try? decoder.decode(SocketMessage.RichMessageResponse.self, from: data) {
      guard let conversationID = richContentMessage.conversationID else {
        print("Warning: RichMessageResponse missing conversationID")
        return
      }

      self.queryAreas[conversationID] = []

      let data: Data?
      var dbID: String?

      switch richContentMessage.kind {
      case .newGoals(let content):
        data = try? JSONEncoder.bloomModel.encode(content)
      case .detectedFood(let content):
        data = try? JSONEncoder.bloomModel.encode(content)
        if !richContentMessage.isTemporary {
          dbID = try? await self.autoLog(detectedFood: content)
        }
      case .logWeight(let content):
        data = try? JSONEncoder.bloomModel.encode(content)
        if !richContentMessage.isTemporary {
          dbID = try? await self.autoLog(logWeight: content)
        }
      case .logPeriod(let content):
        data = try? JSONEncoder.bloomModel.encode(content)
        if !richContentMessage.isTemporary {
          dbID = try? await self.autoLog(logPeriod: content)
        }
      case .logWater(let content):
        data = try? JSONEncoder.bloomModel.encode(content)
        if !richContentMessage.isTemporary {
          dbID = try? await self.autoLog(logWater: content)
        }
      case .logBloodPressure(let content):
        data = try? JSONEncoder.bloomModel.encode(content)
        if !richContentMessage.isTemporary {
          dbID = try? await self.autoLog(logBloodPressure: content)
        }
      case .logBowelMovement(let content):
        data = try? JSONEncoder.bloomModel.encode(content)
        if !richContentMessage.isTemporary {
          dbID = try? await self.autoLog(logBowelMovement: content)
        }
      case .createWorkout(let content):
        data = try? JSONEncoder.bloomModel.encode(content)
        // Workouts might need special handling - not auto-logging for now
      case .createReminder(let content):
        data = try? JSONEncoder.bloomModel.encode(content)
        if !richContentMessage.isTemporary {
          dbID = try? await self.autoLog(createReminder: content)
        }
      case .deleteReminder(let content):
        data = try? JSONEncoder.bloomModel.encode(content)
        if !richContentMessage.isTemporary {
          dbID = try? await self.autoLog(deleteReminder: content)
        }
      case .createUserFacts(let content):
        data = try? JSONEncoder.bloomModel.encode(content)
        if !richContentMessage.isTemporary {
          dbID = try? await self.autoLog(createUserFacts: content)
        }
      case .deleteUserFacts(let content):
        data = try? JSONEncoder.bloomModel.encode(content)
        if !richContentMessage.isTemporary {
          dbID = try? await self.autoLog(deleteUserFacts: content)
        }
      case .invalid(let json):
        data = json.data(using: .utf8)
        TelemetryDeck.signal("Chat - Invalid JSON", parameters: ["json": json])
      }

      guard let data else { return }

      if richContentMessage.isTemporary {
        let inProgressMessage = InProgressMessage(id: richContentMessage.id, data: data, conversationID: conversationID)
        var messages = self.internalInProgressMessages[conversationID] ?? []
        messages.append(inProgressMessage)
        self.internalInProgressMessages[conversationID] = messages
        self.inProgressMessagesIndex[conversationID] = (self.inProgressMessagesIndex[conversationID] ?? 0) + 2 // One for the JSON, and we immediately move to the next message
      } else {
        try? await self.insertRichChatMessage(
          id: richContentMessage.id,
          data: data,
          conversationID: conversationID,
          markActionTaken: dbID != nil,
          dbID: dbID,
          responseID: richContentMessage.responseID,
          requestID: richContentMessage.requestID
        )

        TelemetryDeck.signal(
          "Received Bud Rich Content Message",
          parameters: [
            "richContentKind": richContentMessage.kind.telemetryName
          ]
        )
      }
    } else if let toolCallRequest = try? decoder.decode(SocketMessage.ToolCallsRequest.self, from: data) {
      await TelemetryDeck.stopAndSendDurationSignal("Chat TTFTC")

      // Extract the request ID, conversationID, and lastMessageID from the tool call request
      let requestIDForResponse = toolCallRequest.requestID
      let conversationID = toolCallRequest.conversationID
      let lastMessageID = toolCallRequest.lastMessageID

      // Increment tool request count
      toolRequestCount += 1

      // Collect all tool call IDs
      for toolCall in toolCallRequest.toolCalls {
        toolCallIDs.insert(toolCall.toolCallID)
      }

      do {
        let toolCallsResponses: [SocketMessage.ToolCallResult] = try await withThrowingTaskGroup(of: SocketMessage.ToolCallResult.self, returning: [SocketMessage.ToolCallResult].self) { [self, queryPerformer] taskGroup in
          for toolCall in toolCallRequest.toolCalls {
            taskGroup.addTask {
              switch toolCall.kind {
              case .queries(let queries):

                let queryNames = queries.map { $0.dataType.name }
                if let conversationID {
                  await self.record(queryAreas: queryNames, conversationID: conversationID)
                }

                let results: [String] = await withTaskGroup(of: String.self) { group in
                  for query in queries {
                    group.addTask {
                      await queryPerformer.perform(query: query)
                    }
                  }
                  var allResults = [String]()
                  for await result in group {
                    allResults.append(result)
                  }
                  return allResults
                }

                let data = results.joined(separator: "\n\n")

                return SocketMessage.ToolCallResult(toolCallID: toolCall.toolCallID, data: data)
              }
            }
          }
          var results = [SocketMessage.ToolCallResult]()
          for try await response in taskGroup {
            results.append(response)
          }
          return results
        }

        let responseMessage = SocketMessage.ToolCallsResponse(
          runID: toolCallRequest.runID,
          toolCallResults: toolCallsResponses,
          requestID: requestIDForResponse,
          conversationID: conversationID,
          lastMessageID: lastMessageID
        )

        if let socket = webSocketHandle {
          try await socket.send(payload: responseMessage)
        } else {
          try await NetworkRequester.shared.submitToolCallResponse(body: responseMessage)
        }
      } catch {
        // If we throw, just return an empty set.
        let responseMessage = SocketMessage.ToolCallsResponse(
          runID: toolCallRequest.runID,
          toolCallResults: toolCallRequest.toolCalls.map { SocketMessage.ToolCallResult(toolCallID: $0.toolCallID) },
          requestID: requestIDForResponse,
          conversationID: conversationID,
          lastMessageID: lastMessageID
        )
        if let socket = webSocketHandle {
          try? await socket.send(payload: responseMessage)
        } else {
          try? await NetworkRequester.shared.submitToolCallResponse(body: responseMessage)
        }
        TelemetryDeck.errorOccurred(
          id: "ChatController.handleToolCallRequest",
          category: .thrownException,
          message: error.localizedDescription
        )
//        self.error = error
      }
    } else if let typingIndicator = try? decoder.decode(SocketMessage.TypingIndicator.self, from: data) {
      if let conversationID = typingIndicator.conversationID {
        self.assistantIsTyping[conversationID] = typingIndicator.isTyping

        if typingIndicator.isTyping {
          self.queryAreas[conversationID] = []
        }
      }
    } else if let responseCompleted = try? decoder.decode(SocketMessage.ResponseCompleted.self, from: data) {
      TelemetryDeck.signal("Response Completed")

      // Send telemetry before clearing
      sendToolCallCountTelemetry()
      sendToolRequestCountTelemetry()

      // Clear the current request ID when the response completes
      currentRequestID = nil

      if let conversationID = responseCompleted.conversationID {
        conversationInProgress[conversationID] = false
      }

      // Emit lastMessageID update if present
      if let conversationID = responseCompleted.conversationID, let lastMessageID = responseCompleted.lastMessageID {
        self.lastMessageIDUpdate = LastMessageIDUpdate(
          conversationID: conversationID,
          lastMessageID: lastMessageID
        )
      }
    } else if let conversationNameUpdate = try? decoder.decode(SocketMessage.ConversationNameUpdate.self, from: data) {
      do {
        _ = try await conversationActor.updateConversationName(
          conversationID: conversationNameUpdate.conversationID,
          name: conversationNameUpdate.name
        )
      } catch {
        TelemetryDeck.errorOccurred(
          id: "ChatController.updateConversationName",
          category: .thrownException,
          message: error.localizedDescription
        )
      }
    } else if let error = try? decoder.decode(SocketMessage.Error.self, from: data) {
      self.error = NSError(description: error.errorMessage)
      print(error.errorMessage)

      if let conversationID = error.conversationID {
        conversationInProgress[conversationID] = false
      }

      TelemetryDeck.errorOccurred(
        id: "ChatController.parseData",
        category: .thrownException,
        message: error.errorMessage
      )
    } else {
      print("Unknown SocketMessage:\n\n\(String(data: data, encoding: .utf8) ?? "")")
    }
  }

  func record(queryAreas: [String], conversationID: String) {
    var areas = self.queryAreas[conversationID] ?? []
    for area in queryAreas {
      guard !areas.contains(area) else { continue }
      areas.append(area)
    }
    self.queryAreas[conversationID] = areas
  }

  func insertRichChatMessage(
    id: String,
    data: Data,
    conversationID: String,
    markActionTaken: Bool = false,
    dbID: String? = nil,
    responseID: String? = nil,
    requestID: String? = nil
  ) async throws {
    let conversationModel = try getConversationModel(id: conversationID)
    let richContentMessage = ChatMessage(
      id: id,
      isCurrentUser: false,
      richContent: data,
      dbID: dbID,
      hasPerformedAction: markActionTaken,
      responseID: responseID,
      requestID: requestID,
      conversation: conversationModel
    )
    try await saveMessage(richContentMessage)
  }

  // MARK: - Helper Methods

  /// Fetch a conversation model object (not DTO) for assigning to messages
  private func getConversationModel(id conversationID: String) throws -> ChatConversation {
    let predicate = #Predicate<ChatConversation> { conversation in
      conversation.id == conversationID
    }
    let descriptor = FetchDescriptor<ChatConversation>(predicate: predicate)

    if let existing = try modelContext.fetch(descriptor).first {
      return existing
    }

    // Create if it doesn't exist
    let conversation = ChatConversation(
      id: conversationID,
      name: "Chat",
      createdDate: .now
    )
    modelContext.insert(conversation)
    try modelContext.save()
    return conversation
  }

  /// Save a message to SwiftData. ChatHistoryModifier instances will observe and update.
  private func saveMessage(_ message: ChatMessage) async throws {
    modelContext.insert(message)

    // Update conversation's updatedAt timestamp so it sorts to the top
    if let conversation = message.conversation {
      conversation.updatedAt = .now
    }

    try modelContext.save()
    conversationIDToRefresh = message.conversation?.id
  }

  func autoLog(logWater: SocketMessage.LogWaterConsumption) async throws -> String {
    let quantity = HKQuantity(
      unit: HKUnit(from: logWater.unit.rawValue),
      doubleValue: logWater.amount
    )

    let sample = HKQuantitySample(
      type: HKQuantityType(.dietaryWater),
      quantity: quantity,
      start: Date.now,
      end: Date.now,
      metadata: [
        HKMetadataKeyWasUserEntered: true
      ]
    )

    try await HealthStoreModifier.shared.write(sample)

    TelemetryDeck.signal("Log Water")

    SoundPlayer.playLogHealthData()

    return sample.uuid.uuidString
  }

  func autoLog(detectedFood: SocketMessage.DetectedFood) async throws -> String {
    let servings = detectedFood.foodItemServings.map { $0.asServing() }

    return try await Task { @MainActor in
      let modelContext = ContainerHolder.shared.createContext()
      let foodLogID = try await NutritionTrackingViewModel.shared.log(
        modelContext: modelContext,
        name: detectedFood.name,
        imageData: nil, // TODO: Link image from chat?
        numberOfServings: 1,
        foodItemServings: servings,
        date: detectedFood.date ?? .now,
        meal: detectedFood.meal.asMeal
      )
      SoundPlayer.playLogHealthData()
      return foodLogID
    }
    .value
  }

  func autoLog(logWeight: SocketMessage.LogWeight) async throws -> String {
    let unit: HKUnit = logWeight.unit == .kg ? .gramUnit(with: .kilo) : .pound()
    let quantity = HKQuantity(unit: unit, doubleValue: logWeight.value)
    
    let sample = HKQuantitySample(
      type: HKQuantityType(.bodyMass),
      quantity: quantity,
      start: Date.now,
      end: Date.now,
      metadata: [
        HKMetadataKeyWasUserEntered: true
      ]
    )
    
    try await HealthStoreModifier.shared.write(sample)
    
    TelemetryDeck.signal("Log Weight")
    
    SoundPlayer.playLogHealthData()
    
    return sample.uuid.uuidString
  }

  func autoLog(logPeriod: SocketMessage.LogPeriod) async throws -> String? {
    let flowValue: HKCategoryValueVaginalBleeding
    switch logPeriod.flow {
    case .none:
      flowValue = .unspecified
    case .light:
      flowValue = .light
    case .medium:
      flowValue = .medium
    case .heavy:
      flowValue = .heavy
    }

    let uuid = try await HealthStoreModifier.shared.log(flowType: flowValue, date: .now)

    TelemetryDeck.signal("Log Period")
    
    SoundPlayer.playLogHealthData()
    
    return uuid?.uuidString
  }

  func autoLog(logBloodPressure: SocketMessage.LogBloodPressure) async throws -> String {
    let combinedDBID = try await HealthStoreModifier.shared.log(
      systolic: Double(logBloodPressure.systolic),
      diastolic: Double(logBloodPressure.diastolic)
    )
    
    SoundPlayer.playLogHealthData()
    
    return combinedDBID
  }

  func autoLog(logBowelMovement: SocketMessage.LogBowelMovement) async throws -> String {
    // Store the bowel movement in SwiftData since HealthKit doesn't have a direct type for this
    let recordID = UUID().uuidString
    
    try modelContext.savingTransaction {
      let bowelMovement = BowelMovement(
        date: .now,
        bristolStoolType: logBowelMovement.bristolStoolType,
        duration: logBowelMovement.duration.asBowelMovementDuration,
        recordID: recordID
      )
      modelContext.insert(bowelMovement)
    }
    
    TelemetryDeck.signal("Log Bowel Movement")
    
    SoundPlayer.playLogHealthData()
    
    return recordID
  }

  func autoLog(createReminder: SocketMessage.CreateReminder) async throws -> String {
    if let existingID = createReminder.id {
      // Update existing reminder
      _ = try await RemindersManager.shared.updateReminder(
        withID: existingID,
        title: createReminder.title,
        colorHex: createReminder.color,
        occurrences: createReminder.occurrences.map { occurrence in
          ReminderOccurrence(
            cadenceType: occurrence.cadenceType.asReminderCadenceType,
            timeOfDay: TimeInterval(occurrence.hour * 3600 + occurrence.minute * 60),
            daysOfWeek: occurrence.daysOfWeek?.map { $0.asWeekdayInt },
            dayOfMonth: occurrence.dayOfMonth,
            monthOfYear: occurrence.monthOfYear?.asMonthInt,
            dayOfYear: occurrence.dayOfYear
          )
        }
      )
      TelemetryDeck.signal("Update Reminder")
      return existingID
    } else {
      // Create new reminder
      let reminder = try await RemindersManager.shared.createReminder(
        title: createReminder.title,
        colorHex: createReminder.color,
        occurrences: createReminder.occurrences.map { occurrence in
          ReminderOccurrence(
            cadenceType: occurrence.cadenceType.asReminderCadenceType,
            timeOfDay: TimeInterval(occurrence.hour * 3600 + occurrence.minute * 60),
            daysOfWeek: occurrence.daysOfWeek?.map { $0.asWeekdayInt },
            dayOfMonth: occurrence.dayOfMonth,
            monthOfYear: occurrence.monthOfYear?.asMonthInt,
            dayOfYear: occurrence.dayOfYear
          )
        }
      )
      TelemetryDeck.signal("Create Reminder")
      return reminder.id
    }
  }

  func autoLog(deleteReminder: SocketMessage.DeleteReminder) async throws -> String {
    // Delete the reminder using RemindersManager
    try await RemindersManager.shared.deleteReminder(withID: deleteReminder.reminderID)
    
    TelemetryDeck.signal("Delete Reminder")
    
    // Note: Not playing sound for deletions as it might be jarring
    
    return deleteReminder.reminderID
  }

  func autoLog(createUserFacts: SocketMessage.CreateUserFacts) async throws -> String {
    let userFactModelActor = UserFactModelActor.standard()
    let factInputs = createUserFacts.facts.map { fact in
      (fact: fact.fact, dateAdded: Date(), revisitDate: fact.revisitDate)
    }
    
    let createdFacts = try await userFactModelActor.createUserFacts(factInputs)
    
    TelemetryDeck.signal("Create User Facts", parameters: [
      "count": String(createdFacts.count)
    ])
    
    // Return the first fact ID for dbID tracking
    return createdFacts.first?.id ?? UUID().uuidString
  }

  func autoLog(deleteUserFacts: SocketMessage.DeleteUserFacts) async throws -> String {
    let userFactModelActor = UserFactModelActor.standard()
    let factIDs = deleteUserFacts.facts.map { $0.id }
    let deletedCount = try await userFactModelActor.deleteUserFacts(withIDs: factIDs)
    
    TelemetryDeck.signal("Delete User Facts", parameters: [
      "count": String(deletedCount)
    ])
    
    // Return the first fact ID for dbID tracking
    return deleteUserFacts.facts.first?.id ?? UUID().uuidString
  }

  func on(error: Error) {
    self.error = error
  }

  func onDisconnection() {
    webSocketHandle = nil
    webSocketDataTask = nil
    webSocketDisconnectionTask = nil
    webSocketErrorTask = nil
    assistantIsTyping.removeAll()
    queryAreas.removeAll()
    conversationInProgress.removeAll()
  }
  
  func sendToolCallCountTelemetry() {
    guard !toolCallIDs.isEmpty else { return }
    
    TelemetryDeck.signal(
      "Chat Tool Call Count",
      floatValue: Double(toolCallIDs.count)
    )
    
    // Reset the tool call IDs after sending
    toolCallIDs.removeAll()
  }
  
  func sendToolRequestCountTelemetry() {
    guard toolRequestCount > 0 else { return }

    TelemetryDeck.signal(
      "Chat Tool Request Count",
      floatValue: Double(toolRequestCount)
    )

    // Reset the tool request count after sending
    toolRequestCount = 0
  }

  // MARK: - Privacy Controls

  func getEnabledCategories() async -> Set<AIHealthCategory> {
    await AIDataSharingSettings.shared.enabledCategories
  }
}
