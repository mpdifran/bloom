//
//  ChatViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation

final class ChatViewModel: ObservableObject {
    @Published var chatHistory = [ChatMessage]()

    init() { }
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
                    supplementReccomendation: [],
                    isCurrentUser: true
                )
            )
        }

        let userInfo = HealthManager.shared.userInfo

        let response = try await NetworkRequester.shared.sendQuery(
            prompt: prompt,
            userInfo: userInfo
        )

        await MainActor.run {
            chatHistory.append(
                ChatMessage(
                    message: nil,
                    supplementReccomendation: response,
                    isCurrentUser: false
                )
            )
        }
    }
}
