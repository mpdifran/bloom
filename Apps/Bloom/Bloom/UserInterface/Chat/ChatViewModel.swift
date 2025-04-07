//
//  ChatViewModel.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-02-16.
//

import Foundation
import BloomModel

@Observable @MainActor
final class ChatViewModel {
  var assistantIsTyping = false
  var chatMessages = [ChatMessage]()
  var error: Error?

  private var webSocketHandle: WebSocketHandle?
  private var webSocketDataTask: Task<Void, Never>?

  private let queryPerformer = ChatHealthQueryPerformer()

  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel

  deinit {
    print("Deinit ChatViewModel")
  }
}

extension ChatViewModel {

  func sendMessage(_ message: String) async {
    do {
      let userMessage = ChatMessage(message: message, isCurrentUser: true)
      chatMessages.append(userMessage)

      let demographics = await ChatVitalConverter.shared.generateDemographics()
      let data = try encoder.encode(demographics)
      let stringData = String(data: data, encoding: .utf8) ?? ""

      let socketMessage = SocketMessage.MessageRequest(
        text: message,
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

    webSocketHandle = handle
    return handle
  }

  func parse(data: Data) async {
    if let messagesResponse = try? decoder.decode(SocketMessage.MessagesResponse.self, from: data) {
      for message in messagesResponse.texts {
        let chatMessage = ChatMessage(
          message: message,
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
}
