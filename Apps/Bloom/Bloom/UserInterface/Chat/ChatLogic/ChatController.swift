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
import CoreHealth
import HealthKit
import TelemetryDeck

extension ChatController {
  struct InProgressMessage: Identifiable, Hashable, Sendable {
    let id: String
    var message: String
    let data: Data?

    init(id: String, message: String) {
      self.id = id
      self.message = message
      self.data = nil
    }

    init(id: String, data: Data) {
      self.id = id
      self.message = ""
      self.data = data
    }
  }
}

final actor ChatController: ObservableObject {
  static let shared = ChatController()

  @AsyncStreamable var assistantTypingStatus: String?
  @AsyncStreamable var assistantIsTyping = false
  @AsyncStreamable var inProgressMessages = [InProgressMessage]()
  private var inProgressMessagesIndex = 0
  @AsyncStreamable var error: Error?

  @AppStorage(.FeatureFlag.enableOpenAIModelOverride) private var enableOpenAIModelOverride = false

  private init() { }

  private var queryAreas = [String]() {
    didSet {
      if queryAreas.isEmpty {
        assistantTypingStatus = nil
      } else {
        if let listContent = listFormatter.string(from: queryAreas) {
          assistantTypingStatus = "Reading \(listContent)..."
        } else {
          assistantTypingStatus = nil
        }
      }
    }
  }

  private var webSocketHandle: WebSocketHandle?
  private var webSocketDataTask: Task<Void, Never>?
  private var webSocketDisconnectionTask: Task<Void, Never>?
  private var webSocketErrorTask: Task<Void, Never>?

  private var throttleTask: Task<Void, Never>?
  private let throttleInterval: UInt64 = 100_000_000  // 100 ms in nanoseconds
  private var lastEmitTime: UInt64 = 0
  private var pendingInternalInProgressMessages: [InProgressMessage]?
  private var internalInProgressMessages = [InProgressMessage]() {
    didSet {
      let now = DispatchTime.now().uptimeNanoseconds
      let newValue = internalInProgressMessages
      // If enough time has passed since last emit, send immediately
      if now - lastEmitTime >= throttleInterval {
        lastEmitTime = now
        inProgressMessages = newValue
      } else {
        // Buffer the latest value
        pendingInternalInProgressMessages = newValue
        // Schedule a trailing emit if not already scheduled
        if throttleTask == nil {
          // Calculate remaining wait time
          let wait = throttleInterval - (now - lastEmitTime)
          throttleTask = Task {
            // Sleep for the remainder of the interval
            try? await Task.sleep(nanoseconds: wait)
            // After interval, emit the buffered value if still present
            if let valueToEmit = pendingInternalInProgressMessages {
              lastEmitTime = DispatchTime.now().uptimeNanoseconds
              inProgressMessages = valueToEmit
              pendingInternalInProgressMessages = nil
            }
            throttleTask = nil
          }
        }
      }
    }
  }

  private let listFormatter = ListFormatter()
  private let modelContext = ContainerHolder.shared.createContext()
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

  func send(message: String, image: UIImage?) async throws {
    // Send any pending telemetry before starting a new message
    sendToolCallCountTelemetry()
    sendToolRequestCountTelemetry()
    
    // Generate a new request ID
    let requestID = "request_\(UUID().uuidString)"
    currentRequestID = requestID
    
    let imageData = image?.resized(toWidth: 800)?.pngData()
    let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

    if let imageData {
      let imageMessage = ChatMessage(
        isCurrentUser: true,
        imageData: imageData,
        requestID: requestID
      )
      try await ChatHistoryModifier.shared.addMessage(imageMessage)
    }

    if trimmedMessage.isNotEmpty {
      let userMessage = ChatMessage(
        isCurrentUser: true,
        message: message,
        requestID: requestID
      )
      try await ChatHistoryModifier.shared.addMessage(userMessage)
    }

    let demographics = await ChatVitalConverter.shared.generateDemographics()
    let stringData = try encoder.encodeToString(demographics) ?? ""

    let fileIDs: [String]
    if let imageData {
      fileIDs = try await NetworkRequester.shared.uploadChatImages(images: [imageData]).fileIDs
    } else {
      fileIDs = []
    }

    guard trimmedMessage.isNotEmpty || fileIDs.isNotEmpty else { return }

    let socketMessage = SocketMessage.MessageRequest(
      text: trimmedMessage,
      imageFileIDs: fileIDs,
      userInfo: stringData,
      requestID: requestID
    )

    let socket = await createOrGetWebSocketHandle()
    try await socket.send(payload: socketMessage)

    await SoundPlayer.playSendMessage()

    TelemetryDeck.signal(
      "Send Chat Message",
      parameters: [
        "includesChatImages": fileIDs.isNotEmpty ? "Yes" : "No",
        "name": await UserController.shared.fullUserIdentifier
      ]
    )

    await TelemetryDeck.startDurationSignal("Chat TTFT")
    await TelemetryDeck.startDurationSignal("Chat TTFTC")
  }

  func sendSystemContextMessage(dummyAssistantMessage: String?, systemContext: String) async throws {
    // Generate a new request ID
    let requestID = "request_\(UUID().uuidString)"
    currentRequestID = requestID

    if let dummyAssistantMessage {
      let assistantMessage = ChatMessage(
        isCurrentUser: false,
        message: dummyAssistantMessage,
        requestID: requestID
      )
      try await ChatHistoryModifier.shared.addMessage(assistantMessage)
    }

    let demographics = await ChatVitalConverter.shared.generateDemographics()
    let stringData = try encoder.encodeToString(demographics) ?? ""

    let socketMessage = SocketMessage.MessageRequest(
      text: "",
      imageFileIDs: [],
      userInfo: stringData,
      extraSystemContext: systemContext,
      requestID: requestID
    )

    let socket = await createOrGetWebSocketHandle()
    try await socket.send(payload: socketMessage)
  }

  func handlePushData(_ data: Data) async {
    await parse(data: data)
  }
}

private extension ChatController {

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

      do {
        let message = ChatMessage(
          id: messageResponse.id,
          isCurrentUser: false,
          message: messageResponse.message,
          responseID: messageResponse.responseID,
          requestID: messageResponse.requestID
        )
        try await ChatHistoryModifier.shared.addMessage(message)
        TelemetryDeck.signal("Received Bud Text Message")
      } catch {
        self.error = error
      }

      self.inProgressMessagesIndex = 0
      self.internalInProgressMessages = []
      self.queryAreas.removeAll()
      self.assistantIsTyping = false

    } else if let messageChunk = try? decoder.decode(SocketMessage.MessageChunkResponse.self, from: data) {

      self.queryAreas.removeAll()

      if self.internalInProgressMessages.count > self.inProgressMessagesIndex {
        self.internalInProgressMessages[self.inProgressMessagesIndex].message += messageChunk.chunk
      } else {
        let inProgressMessage = InProgressMessage(id: messageChunk.id, message: messageChunk.chunk)
        self.internalInProgressMessages.append(inProgressMessage)

        await TelemetryDeck.stopAndSendDurationSignal("Chat TTFT")
      }
    } else if let richContentMessage = try? decoder.decode(SocketMessage.RichMessageResponse.self, from: data) {

      self.queryAreas.removeAll()

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
        let inProgressMessage = InProgressMessage(id: richContentMessage.id, data: data)
        self.internalInProgressMessages.append(inProgressMessage)
        self.inProgressMessagesIndex += 2 // One for the JSON, and we immediately move to the next message
      } else {
        try? await self.insertRichChatMessage(
          id: richContentMessage.id, 
          data: data,
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

      // Extract the request ID from the tool call request
      let requestIDForResponse = toolCallRequest.requestID

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
                await self.record(queryAreas: queryNames)

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
          requestID: requestIDForResponse
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
          requestID: requestIDForResponse
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
      self.assistantIsTyping = typingIndicator.isTyping

      if self.assistantIsTyping {
        self.queryAreas.removeAll()
      }
    } else if let _ = try? decoder.decode(SocketMessage.ResponseCompleted.self, from: data) {

      TelemetryDeck.signal("Response Completed")
      
      // Send telemetry before clearing
      sendToolCallCountTelemetry()
      sendToolRequestCountTelemetry()
      
      // Clear the current request ID when the response completes
      currentRequestID = nil
    } else if let error = try? decoder.decode(SocketMessage.Error.self, from: data) {
      self.error = NSError(description: error.errorMessage)
      print(error.errorMessage)
      TelemetryDeck.errorOccurred(
        id: "ChatController.parseData",
        category: .thrownException,
        message: error.errorMessage
      )
    } else {
      print("Unknown SocketMessage:\n\n\(String(data: data, encoding: .utf8) ?? "")")
    }
  }

  func record(queryAreas: [String]) {
    for area in queryAreas {
      guard !self.queryAreas.contains(area) else { continue }

      self.queryAreas.append(area)
    }
  }

  func insertRichChatMessage(
    id: String,
    data: Data,
    markActionTaken: Bool = false,
    dbID: String? = nil,
    responseID: String? = nil,
    requestID: String? = nil
  ) async throws {
    let richContentMessage = ChatMessage(
      id: id,
      isCurrentUser: false,
      richContent: data,
      dbID: dbID,
      hasPerformedAction: markActionTaken,
      responseID: responseID,
      requestID: requestID
    )
    try await ChatHistoryModifier.shared.addMessage(richContentMessage)
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
        image: nil, // TODO: Link image from chat?
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
    assistantIsTyping = false
    queryAreas.removeAll()
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
}
