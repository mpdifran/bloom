//
//  ChatViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation

final class ChatViewModel: ObservableObject {
    static let shared = ChatViewModel()

    @Published var chatHistory = [ChatMessage]()

    private init() { }
}

extension ChatViewModel {

    func lastID() -> String? {
        let lastMessage = chatHistory.last
        if let lastReccomendation = lastMessage?.supplementReccomendation.last {
            return lastReccomendation.id
        }
        return lastMessage?.id
    }

    func send(prompt: String) async throws {
        await MainActor.run {
            chatHistory.append(
                ChatMessage(
                    message: prompt,
                    timestamp: .now,
                    supplementReccomendation: [],
                    isCurrentUser: true
                )
            )
            SoundPlayer.playSendMessage()
        }

        let userInfo = HealthManager.shared.userInfo
        let currentGoals = GoalViewModel.shared.selectedGoals
        let currentSupplements = SupplementViewModel.shared.selectedSupplements

        let response = try await NetworkRequester.shared.sendQuery(
            prompt: prompt,
            userInfo: userInfo,
            currentGoals: currentGoals,
            currentSupplements: currentSupplements,
            chatHistory: networkChatHistory
        )

        await MainActor.run {
            var hasSentMessage = false
            if let answer = response.message {
                chatHistory.append(
                    ChatMessage(
                        message: answer,
                        timestamp: .now,
                        supplementReccomendation: [],
                        isCurrentUser: false
                    )
                )
                hasSentMessage = true
            }
            if let recommendations = response.recommendedSupplements, recommendations.isNotEmpty {
                chatHistory.append(
                    ChatMessage(
                        message: nil,
                        timestamp: .now,
                        supplementReccomendation: recommendations,
                        isCurrentUser: false
                    )
                )
                hasSentMessage = true
            }

            if hasSentMessage {
                SoundPlayer.playReceiveMessage()
            }
        }
    }

    func sendProactiveTip() async {
        let userInfo = HealthManager.shared.userInfo
        let currentGoals = GoalViewModel.shared.selectedGoals
        let currentSupplements = SupplementViewModel.shared.selectedSupplements

        do {
            let response = try await NetworkRequester.shared.sendProactiveTip(
                userInfo: userInfo,
                currentGoals: currentGoals,
                currentSupplements: currentSupplements,
                chatHistory: networkChatHistory
            )

            await MainActor.run {
                chatHistory.append(
                    ChatMessage(
                        message: response.message,
                        timestamp: .now,
                        supplementReccomendation: [],
                        isCurrentUser: false
                    )
                )
            }

            await NotificationManager.shared.sendNotification(title: "Bloom", subtitle: response.message)
        } catch {
            print(error)
        }
    }
}

extension ChatViewModel {

    var networkChatHistory: [ChatMessageHistory] {
        chatHistory.map { chatMessage in
            let message = chatMessage.message ?? chatMessage.supplementReccomendation.first?.shortText ?? ""

            return ChatMessageHistory(
                timestamp: chatMessage.timestamp,
                message: message,
                sender: chatMessage.isCurrentUser ? "User" : "Bloom"
            )
        }
    }
}
