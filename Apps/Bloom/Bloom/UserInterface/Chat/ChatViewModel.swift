//
//  ChatViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import SwiftUI
import BloomModel

@Observable @MainActor
final class ChatViewModel {
  var assistantIsTyping = false
  var chatMessages = [ChatMessage]()
  var error: Error?

  private var webSocketHandle: WebSocketHandle?
  private var webSocketDataTask: Task<Void, Never>?
  private var webSocketDisconnectionTask: Task<Void, Never>?
  private var webSocketErrorTask: Task<Void, Never>?

  private let queryPerformer = ChatHealthQueryPerformer()

  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel

  deinit {
    print("Deinit ChatViewModel")
  }
}

extension ChatViewModel {

  func sendMessage(_ message: String, image: UIImage?) async {
    do {
      let userMessage = ChatMessage(
        message: message,
        image: image,
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
    webSocketErrorTask = Task.detached { [weak self] in
      for await error in await handle.$error {
        if let error {
          await self?.on(error: error)
        }
      }
    }

    webSocketHandle = handle
    return handle
  }

  func parse(data: Data) async {
    if let messagesResponse = try? decoder.decode(SocketMessage.MessagesResponse.self, from: data) {
      for message in messagesResponse.texts {
        let chatMessage = ChatMessage(
          message: message,
          image: nil,
          isCurrentUser: false
        )
        chatMessages.append(chatMessage)
      }
    } else if let queryResponse = try? decoder.decode(SocketMessage.DataQueryResponse.self, from: data) {
      let queryData = await perform(queryResponse: queryResponse)

      let dataRequest = SocketMessage.DataQueryRequest(
        id: queryResponse.id,
        queryData: queryData
      )

      if let testData = try? encoder.encode(dataRequest) {
        print("Query Data: \(String(data: testData, encoding: .utf8) ?? "")")
      }

      do {
        try await webSocketHandle?.send(payload: dataRequest)
      } catch {
        self.error = error
      }
    } else if let typingIndicator = try? decoder.decode(SocketMessage.TypingIndicator.self, from: data) {
      self.assistantIsTyping = typingIndicator.isTyping
    } else if let errorMessage = try? decoder.decode(SocketMessage.Error.self, from: data) {
      self.error = NSError(description: errorMessage.message)
    } else {
      print("Unknown SocketMessage:\n\n\(String(data: data, encoding: .utf8) ?? "")")
    }
  }

  func perform(queryResponse: SocketMessage.DataQueryResponse) async -> [SocketMessage.QueryData] {
    await withTaskGroup(of: SocketMessage.QueryData.self, returning: [SocketMessage.QueryData].self) { taskGroup in
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
  }
}
