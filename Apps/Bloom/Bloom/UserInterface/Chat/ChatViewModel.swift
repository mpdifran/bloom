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
  static let shared = ChatViewModel()

  var chatMessages = [ChatMessage]()

  private var webSocketHandle: WebSocketHandle?
  private var webSocketDataTask: Task<Void, Never>?

  private let encoder = JSONEncoder.bloomModel
  private let decoder = JSONDecoder.bloomModel
}

extension ChatViewModel {

  func sendMessage(_ message: String) async throws {
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
        guard let data else { return }

        await self?.parse(data: data)
      }
    }

    webSocketHandle = handle
    return handle
  }

  func parse(data: Data) {
    if let messagesResponse = try? decoder.decode(SocketMessage.MessagesResponse.self, from: data) {
      for message in messagesResponse.texts {
        let chatMessage = ChatMessage(
          message: message,
          isCurrentUser: false
        )
        chatMessages.append(chatMessage)
      }
    } else if let queryResponse = try? decoder.decode(SocketMessage.DataQueryResponse.self, from: data) {

    } else {
      print("Unknown SocketMessage:\n\n\(String(data: data, encoding: .utf8) ?? "")")
    }
  }
}
