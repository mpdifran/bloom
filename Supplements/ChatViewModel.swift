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

    func send(prompt: String) async throws {
        let userInfo = HealthManager.shared.userInfo

        let response = try await NetworkRequester.shared.sendQuery(prompt: prompt, userInfo: userInfo)

        await MainActor.run {
            chatHistory.append(ChatMessage(message: prompt, isCurrentUser: true))
            chatHistory.append(ChatMessage(message: response.answer, isCurrentUser: false))
        }
    }
}
