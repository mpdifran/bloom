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

  @AppStorage(.FeatureFlag.chatV2) private var chatV2 = false

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
  private let throttleInterval: UInt64 = 50_000_000  // 50 ms in nanoseconds
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
}

extension ChatController {

  func send(message: String, image: UIImage?) async throws {
    let imageData = image?.resized(toWidth: 300)?.pngData()
    let trimmedMessage = message.trimmingCharacters(in: .whitespacesAndNewlines)

    try modelContext.savingTransaction {
      if let imageData {
        let imageMessage = ChatMessage(
          isCurrentUser: true,
          imageData: imageData
        )
        modelContext.insert(imageMessage)
      }

      if trimmedMessage.isNotEmpty {
        let userMessage = ChatMessage(
          isCurrentUser: true,
          message: message
        )
        modelContext.insert(userMessage)
      }
    }

    let demographics = await ChatVitalConverter.shared.generateDemographics()
    let data = try encoder.encode(demographics)
    let stringData = String(data: data, encoding: .utf8) ?? ""

    let fileIDs: [String]
    if let imageData {
      fileIDs = try await NetworkRequester.shared.uploadChatImages(images: [imageData]).fileIDs
    } else {
      fileIDs = []
    }

    let socketMessage = SocketMessage.MessageRequest(
      text: trimmedMessage,
      imageFileIDs: fileIDs,
      userInfo: stringData
    )

    let socket = await createOrGetWebSocketHandle()
    try await socket.send(payload: socketMessage)

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

  func handlePushData(_ data: Data) async {
    await parse(data: data)
  }
}

private extension ChatController {

  func createOrGetWebSocketHandle() async -> WebSocketHandle {
    if let existingHandle = webSocketHandle {
      return existingHandle
    }

    let handle = await NetworkRequester.shared.openChatWebsocket(isV2: chatV2)

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

      do {
        try modelContext.savingTransaction {
          let message = ChatMessage(
            id: messageResponse.id,
            isCurrentUser: false,
            message: messageResponse.message
          )
          modelContext.insert(message)
        }
      } catch {
        self.error = error
      }

      self.inProgressMessagesIndex = 0
      self.internalInProgressMessages = []
      self.queryAreas.removeAll()

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

      let data: Data
      switch richContentMessage.kind {
      case .newGoals(let content):
        data = (try? JSONEncoder.bloomModel.encode(content)) ?? Data()
      case .detectedFood(let content):
        data = (try? JSONEncoder.bloomModel.encode(content)) ?? Data()
      case .logWeight(let content):
        data = (try? JSONEncoder.bloomModel.encode(content)) ?? Data()
      case .logPeriod(let content):
        data = (try? JSONEncoder.bloomModel.encode(content)) ?? Data()
      case .logWater(let content):
        data = (try? JSONEncoder.bloomModel.encode(content)) ?? Data()
      case .logBloodPressure(let content):
        data = (try? JSONEncoder.bloomModel.encode(content)) ?? Data()
      case .logBowelMovement(let content):
        data = (try? JSONEncoder.bloomModel.encode(content)) ?? Data()
      case .createWorkout(let content):
        data = (try? JSONEncoder.bloomModel.encode(content)) ?? Data()
      }

      if richContentMessage.isTemporary {
        let inProgressMessage = InProgressMessage(id: richContentMessage.id, data: data)
        self.internalInProgressMessages.append(inProgressMessage)
        self.inProgressMessagesIndex += 2 // One for the JSON, and we immediately move to the next message
      } else {
        try? self.insertRichChatMessage(id: richContentMessage.id, data: data) // TODO: Handle errors?!
      }
    } else if let toolCallRequest = try? decoder.decode(SocketMessage.ToolCallsRequest.self, from: data) {
      await TelemetryDeck.stopAndSendDurationSignal("Chat TTFTC")
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

              case .newGoals(let goals):
                let data = try JSONEncoder.bloomModel.encode(goals)
                try await self.insertRichChatMessage(id: UUID().uuidString, data: data)
              case .detectedFood(let food):
                let data = try JSONEncoder.bloomModel.encode(food)
                let foodLogID = try await self.autoLog(detectedFood: food)
                try await self.insertRichChatMessage(
                  id: UUID().uuidString,
                  data: data,
                  markActionTaken: true,
                  dbID: foodLogID
                )
              case .logWater(let logWater):
                let data = try JSONEncoder.bloomModel.encode(logWater)
                try await self.insertRichChatMessage(id: UUID().uuidString, data: data)
              case .logWeight(let logWeight):
                let data = try JSONEncoder.bloomModel.encode(logWeight)
                try await self.insertRichChatMessage(id: UUID().uuidString, data: data)
              case .logPeriod(let logPeriod):
                let data = try JSONEncoder.bloomModel.encode(logPeriod)
                try await self.insertRichChatMessage(id: UUID().uuidString, data: data)
              case .logBloodPressure(let logBloodPressure):
                let data = try JSONEncoder.bloomModel.encode(logBloodPressure)
                try await self.insertRichChatMessage(id: UUID().uuidString, data: data)
              case .logBowelMovement(let logBowelMovement):
                let data = try JSONEncoder.bloomModel.encode(logBowelMovement)
                try await self.insertRichChatMessage(id: UUID().uuidString, data: data)
              case .createWorkout(let createWorkout):
                let data = try JSONEncoder.bloomModel.encode(createWorkout)
                try await self.insertRichChatMessage(id: UUID().uuidString, data: data)
              }
              return SocketMessage.ToolCallResult(toolCallID: toolCall.toolCallID)
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
          toolCallResults: toolCallsResponses
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
          toolCallResults: toolCallRequest.toolCalls.map { SocketMessage.ToolCallResult(toolCallID: $0.toolCallID) }
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
    } else if let error = try? decoder.decode(SocketMessage.Error.self, from: data) {
      self.error = NSError(description: error.errorMessage)
      print(error.errorMessage)
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
    dbID: String? = nil
  ) throws {
    try modelContext.savingTransaction {
      let richContentMessage = ChatMessage(
        id: id,
        isCurrentUser: false,
        richContent: data,
        dbID: dbID,
        hasPerformedAction: markActionTaken
      )
      modelContext.insert(richContentMessage)
    }
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
        date: .now,
        meal: detectedFood.meal.asMeal
      )
      SoundPlayer.playLogHealthData()
      return foodLogID
    }
    .value
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
}
