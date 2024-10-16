//
//  ChatViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation
import AppFoundations
import Algorithms

@MainActor
final class ChatViewModel: ObservableObject {
    static let shared = ChatViewModel()

    @Published var isWaitingForResponse = false
    @Published var unreadChatCount = 0

    @Published var chatHistory = [ChatMessage]() {
        didSet {
            do {
                let data = try JSONEncoder.main.encode(Array(chatHistory.suffix(15)))
                UserDefaults.standard.setValue(data, forKey: "chatHistory")
            } catch {
                print(error)
            }
        }
    }

    private init() { 
        if let data = UserDefaults.standard.value(forKey: "chatHistory") as? Data {
            do {
                let chatHistory = try JSONDecoder.main.decode([ChatMessage].self, from: data)
                self.chatHistory = chatHistory
            } catch {
                print(error)
            }
        }
    }
}

extension ChatViewModel {

    func lastID() -> String? {
        let lastMessage = chatHistory.last
        if let lastReccomendation = lastMessage?.supplementReccomendation.last {
            return lastReccomendation.id
        }
        return lastMessage?.id
    }

    func deleteChatHistory() {
        chatHistory = []
    }

    func send(prompt: String, secretContext: String? = nil) async throws {
        
    }

    func appendAssistantMessage(message: String) async {
        await MainActor.run {
            var newChatHistory = chatHistory

            newChatHistory.append(
                ChatMessage(
                    message: message,
                    timestamp: .now,
                    supplementReccomendation: [],
                    activityRecommendation: [],
                    isCurrentUser: false
                )
            )
            unreadChatCount += 1

            chatHistory = newChatHistory

            SoundPlayer.playReceiveMessage()
        }

        await NotificationManager.shared.sendNotification(
            title: "Bloom",
            subtitle: message,
            categoryID: .CategoryID.chatMessage
        )
    }
}

extension ChatViewModel {

    var networkChatHistory: [ChatMessageHistory] {
        chatHistory.map { chatMessage in
            var message = chatMessage.message ?? chatMessage.supplementReccomendation.first?.shortText ?? ""

            if let secretContext = chatMessage.secretContext {
                message += "\n\n" + secretContext
            }

            return ChatMessageHistory(
                role: chatMessage.isCurrentUser ? .user : .assistant,
                content: message
            )
        }
    }
}
