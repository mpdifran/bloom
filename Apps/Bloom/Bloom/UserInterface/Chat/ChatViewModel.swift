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
}

extension ChatViewModel {

  func syncHealthData() async {
    let healthData = await ChatVitalConverter.shared.convertHealthData()

    do {
      let data = try JSONEncoder.bloomModel.encode(healthData)
      guard let stringData = String(data: data, encoding: .utf8) else { return }

      try await NetworkRequester.shared.reportHealthData(healthData: stringData)
    } catch {
      print(error)
    }
  }

  func sendMessage(_ message: String) async {
    let userMessage = ChatMessage(message: message, isCurrentUser: true)
    chatMessages.append(userMessage)
    SoundPlayer.playSendMessage()

    let healthData = await ChatVitalConverter.shared.convertHealthData()

    do {
      let data = try JSONEncoder.bloomModel.encode(healthData)
      let stringData = String(data: data, encoding: .utf8)

      let response = try await NetworkRequester.shared.sendChatMessage(message: message, healthData: stringData)

      let newMessages = response.messages.map {
        ChatMessage(message: $0, isCurrentUser: false)
      }
      chatMessages.append(contentsOf: newMessages)
      SoundPlayer.playReceiveMessage()
    } catch {
      print(error)
    }
  }

  func deleteChatHistory() async throws {
    try await NetworkRequester.shared.deleteChatThread()
    chatMessages.removeAll()
    await ChatVitalConverter.shared.resetSyncDate()
  }
}
