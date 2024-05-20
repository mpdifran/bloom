//
//  ChatViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation
import AppFoundations

final class ChatViewModel: ObservableObject {
    static let shared = ChatViewModel()

    @Published var chatHistory = [ChatMessage]()
    @Published var learnedUserFacts = [String]() {
        didSet {
            UserDefaults.standard.setValue(learnedUserFacts, forKey: "learnedUserFacts")
        }
    }

    private init() { 
        if let learnedUserFacts = UserDefaults.standard.value(forKey: "learnedUserFacts") as? [String] {
            self.learnedUserFacts = learnedUserFacts
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
            userInfo: userInfo,
            currentGoals: currentGoals,
            currentSupplements: currentSupplements,
            chatHistory: networkChatHistory,
            learnedUserFacts: learnedUserFacts
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

            learnedUserFacts = response.learnedUserFacts

            if hasSentMessage {
                SoundPlayer.playReceiveMessage()
            }
        }
    }

    func sendProactiveTip() async {
        do {
            try await HealthManager.shared.loadUserInfo()
        } catch { print(error) }
        let userInfo = HealthManager.shared.userInfo
        let currentGoals = GoalViewModel.shared.selectedGoals
        let currentSupplements = SupplementViewModel.shared.selectedSupplements

        let request = ProactiveTipRequestModel(
            userInfo: userInfo,
            currentSupplements: currentSupplements,
            currentGoals: currentGoals,
            chatHistory: networkChatHistory,
            learnedUserFacts: learnedUserFacts
        )

        do {
            let response = try await NetworkRequester.shared.sendProactiveTip(request: request)

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
                role: chatMessage.isCurrentUser ? .user : .assistant,
                content: message
            )
        }
    }
}
