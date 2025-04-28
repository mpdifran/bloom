//
//  ChatController.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-21.
//

import SwiftUI
import DataContainer
import BloomModel

final actor ChatController: ObservableObject {
  static let shared = ChatController()

  @AsyncStreamable var assistantTypingStatus: String?
  @AsyncStreamable var assistantIsTyping = false
  @AsyncStreamable var scrollToLatestMessageToggle = false
  @AsyncStreamable var error: Error?

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

  private let listFormatter = ListFormatter()
  private let modelContext = ContainerHolder.shared.createContext()
  private let queryPerformer = ChatHealthQueryPerformer()

  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel
}

extension ChatController {

  func send(message: String, image: UIImage?) async throws {
    let imageData = image?.resized(toWidth: 300)?.pngData()

    try modelContext.savingTransaction {
      if let imageData {
        let imageMessage = ChatMessage(
          isCurrentUser: true,
          imageData: imageData
        )
        modelContext.insert(imageMessage)
      }

      let userMessage = ChatMessage(
        isCurrentUser: true,
        message: message
      )
      modelContext.insert(userMessage)
    }

    scrollToLatestMessageToggle.toggle()

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
      text: message,
      imageFileIDs: fileIDs,
      userInfo: stringData
    )

    let socket = await createOrGetWebSocketHandle()
    try await socket.send(payload: socketMessage)

    await SoundPlayer.playSendMessage()
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

    let handle = await NetworkRequester.shared.openChatWebsocket()

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
    print("Recevied data: \(String(data: data, encoding: .utf8) ?? "")")

    if let messagesResponse = try? decoder.decode(SocketMessage.MessageResponse.self, from: data) {

      do {
        try modelContext.savingTransaction {
          let message = ChatMessage(
            isCurrentUser: false,
            message: messagesResponse.message
          )
          modelContext.insert(message)
        }
        scrollToLatestMessageToggle.toggle()
      } catch {
        self.error = error
      }
    } else if let toolCallRequest = try? decoder.decode(SocketMessage.ToolCallsRequest.self, from: data) {
      do {
        let toolCallsResponses: [SocketMessage.ToolCallResult] = try await withThrowingTaskGroup(of: SocketMessage.ToolCallResult.self, returning: [SocketMessage.ToolCallResult].self) { [self, queryPerformer] taskGroup in
          for toolCall in toolCallRequest.toolCalls {
            taskGroup.addTask {
              switch toolCall.kind {
              case .query(let query):
                if let title = query.dataType?.name ?? query.healthMetric?.name {
                  await self.record(queryArea: title)
                }
                let data = await queryPerformer.perform(query: query)
                return SocketMessage.ToolCallResult(toolCallID: toolCall.toolCallID, data: data)
              case .newGoals(let goals):
                let data = try JSONEncoder.bloomModel.encode(goals)
                try await self.insertRichChatMessage(data: data)
              case .detectedFood(let food):
                let data = try JSONEncoder.bloomModel.encode(food)
                try await self.insertRichChatMessage(data: data)
              case .logWater(let logWater):
                let data = try JSONEncoder.bloomModel.encode(logWater)
                try await self.insertRichChatMessage(data: data)
              case .logWeight(let logWeight):
                let data = try JSONEncoder.bloomModel.encode(logWeight)
                try await self.insertRichChatMessage(data: data)
              case .logBloodPressure(let logBloodPressure):
                let data = try JSONEncoder.bloomModel.encode(logBloodPressure)
                try await self.insertRichChatMessage(data: data)
              case .logBowelMovement(let logBowelMovement):
                let data = try JSONEncoder.bloomModel.encode(logBowelMovement)
                try await self.insertRichChatMessage(data: data)
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
        self.error = error
      }
    } else if let typingIndicator = try? decoder.decode(SocketMessage.TypingIndicator.self, from: data) {
      self.assistantIsTyping = typingIndicator.isTyping

      if !typingIndicator.isTyping {
        self.queryAreas.removeAll()
      }
    } else if let error = try? decoder.decode(SocketMessage.Error.self, from: data) {
      self.error = NSError(description: error.errorMessage)
      print(error.errorMessage)
    } else {
      print("Unknown SocketMessage:\n\n\(String(data: data, encoding: .utf8) ?? "")")
    }
  }

  func record(queryArea: String) {
    queryAreas.append(queryArea)
  }

  func insertRichChatMessage(data: Data) throws {
    try modelContext.savingTransaction {
      let richContentMessage = ChatMessage(isCurrentUser: false, richContent: data)
      modelContext.insert(richContentMessage)
    }
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

private extension SocketMessage.QueryDataType {

  var name: String {
    switch self {
    case .foodLogs: "food logs"
    case .nutrition: "nutrition"
    case .goals: "goals"
    case .activityLevel: "activity level"
    case .bodyWeight: "body weight"
    case .bowelMovements: "bowel movements"
    case .heart: "heart health"
    case .menstruation: "cycle tracking"
    case .sleep: "sleep"
    case .stress: "stress"
    case .workouts: "workouts"
    case .targetHeartRateZoneMinutes: "target heart rate zones"
    }
  }
}

private extension SuggestedGoal.Metric {

  var name: String {
    switch self {
    case .calories: "caloric intake"
    case .proteinIntake: "protein intake"
    case .waterIntake: "water intake"
    case .fiberIntake: "fiber intake"
    case .meditationMinutes: "meditation minutes"
    case .exerciseMinutes: "exercise minutes"
    case .stepCount: "steps"
    case .walkingRunningDistance: "walking-running distance"
    case .runDistance: "running distance"
    case .runDuration: "running duration"
    case .bikeDistance: "biking distance"
    case .bikeDuration: "biking duration"
    case .mobilityAndFlexibilityDuration: "mobility and flexibility workouts"
    case .strengthTrainingDuration: "strength training workouts"
    case .cardioDuration: "cardio workouts"
    case .highIntensityIntervalTrainingDuration: "HIIT workouts"
    case .targetHeartRateZone1Minutes: "target heart rate zone 1 minutes"
    case .targetHeartRateZone2Minutes: "target heart rate zone 2 minutes"
    case .targetHeartRateZone3Minutes: "target heart rate zone 3 minutes"
    case .targetHeartRateZone4Minutes: "target heart rate zone 4 minutes"
    case .targetHeartRateZone5Minutes: "target heart rate zone 5 minutes"
    }
  }
}
