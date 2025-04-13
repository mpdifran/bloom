//
//  ChatViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import SwiftUI
import BloomModel
import DataContainer

@Observable @MainActor
final class ChatViewModel {
  var assistantTypingStatus: String?
  var assistantIsTyping = false
  var chatMessages = [ChatMessage]()
  var error: Error?

  private var webSocketHandle: WebSocketHandle?
  private var webSocketDataTask: Task<Void, Never>?
  private var webSocketDisconnectionTask: Task<Void, Never>?
  private var webSocketErrorTask: Task<Void, Never>?
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

  private let listFormatter = ListFormatter()
  private let queryPerformer = ChatHealthQueryPerformer()

  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel

  private let modelActor = HabitModelActor.standard()

  deinit {
    print("Deinit ChatViewModel")
  }
}

extension ChatViewModel {

  func sendMessage(_ message: String, image: UIImage?) async {
    do {
      if let image {
        let imageMessage = ChatMessage(
          content: .image(image),
          isCurrentUser: true
        )
        chatMessages.append(imageMessage)
      }

      let userMessage = ChatMessage(
        content: .text(message),
        isCurrentUser: true
      )
      chatMessages.append(userMessage)

      let demographics = await ChatVitalConverter.shared.generateDemographics()
      let data = try encoder.encode(demographics)
      let stringData = String(data: data, encoding: .utf8) ?? ""

      let fileIDs: [String]
      if let data = image?.resized(toWidth: 300)?.pngData() {
        fileIDs = try await NetworkRequester.shared.uploadChatImages(images: [data]).fileIDs
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

      SoundPlayer.playSendMessage()
    } catch {
      self.error = error
    }
  }

  func deleteChatHistory() async throws {
    try await NetworkRequester.shared.deleteChatThread()
    chatMessages.removeAll()
  }
}

private extension ChatViewModel {

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
    // These errors are too noisy
//    webSocketErrorTask = Task.detached { [weak self] in
//      for await error in await handle.$error {
//        if let error {
//          await self?.on(error: error)
//        }
//      }
//    }

    webSocketHandle = handle
    return handle
  }

  func parse(data: Data) async {
    if let messagesResponse = try? decoder.decode(SocketMessage.MessageResponse.self, from: data) {
      let chatMessage = ChatMessage(
        content: .text(messagesResponse.message),
        isCurrentUser: false
      )
      chatMessages.append(chatMessage)

      if let healthGoals = messagesResponse.healthMetricGoals {
        var proposedGoals = [ProposedGoal]()
        for healthGoal in healthGoals {
          let habit = try? await modelActor.fetchActiveHabits(for: healthGoal.metric.targetMetric).first

          let proposedGoal = ProposedGoal(
            habitID: habit?.id,
            targetMetric: healthGoal.metric.targetMetric,
            value: habit?.isUserEdited == true ? habit!.value : healthGoal.value,
            suggestedValue: healthGoal.value,
            previousValue: habit?.value,
            unitString: healthGoal.unit.hkUnit.unitString,
            vitalKind: nil,
            context: "",
            hasUserEdited: habit?.isUserEdited == true
          )
          proposedGoals.append(proposedGoal)
        }
        if proposedGoals.isNotEmpty {
          let chatMessage = ChatMessage(
            content: .goals(proposedGoals),
            isCurrentUser: false
          )
          chatMessages.append(chatMessage)
        }
      }
    } else if let queryResponse = try? decoder.decode(SocketMessage.DataQueryResponse.self, from: data) {
      let queryData = await perform(queryResponse: queryResponse)

      let dataRequest = SocketMessage.DataQueryRequest(
        id: queryResponse.id,
        queryData: queryData
      )

      do {
        try await webSocketHandle?.send(payload: dataRequest)
      } catch {
        self.error = error
      }
    } else if let typingIndicator = try? decoder.decode(SocketMessage.TypingIndicator.self, from: data) {
      self.assistantIsTyping = typingIndicator.isTyping

      if !typingIndicator.isTyping {
        self.queryAreas.removeAll()
      }
    } else if let errorMessage = try? decoder.decode(SocketMessage.Error.self, from: data) {
//      self.error = NSError(description: errorMessage.message)
    } else {
      print("Unknown SocketMessage:\n\n\(String(data: data, encoding: .utf8) ?? "")")
    }
  }

  func perform(queryResponse: SocketMessage.DataQueryResponse) async -> [SocketMessage.QueryData] {
    let titles = queryResponse.queries.flatMap { query in
      [query.dataType?.name, query.healthMetric?.name].compactMap { $0 }
    }
    queryAreas.append(contentsOf: titles)

    return await withTaskGroup(of: SocketMessage.QueryData.self, returning: [SocketMessage.QueryData].self) { taskGroup in
        for query in queryResponse.queries {
            taskGroup.addTask { [queryPerformer] in
                let data = await queryPerformer.perform(query: query)
                return SocketMessage.QueryData(id: query.id, data: data)
            }
        }
        var results: [SocketMessage.QueryData] = []
        for await result in taskGroup {
            results.append(result)
        }
        return results
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
