//
//  ChatViewModel.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-08.
//

import Foundation
import AppFoundations
import Algorithms

final class ChatViewModel: ObservableObject {
    static let shared = ChatViewModel()

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
        await MainActor.run {
            chatHistory.append(
                ChatMessage(
                    message: prompt,
                    secretContext: secretContext,
                    timestamp: .now,
                    supplementReccomendation: [],
                    activityRecommendation: [],
                    isCurrentUser: true
                )
            )
            SoundPlayer.playSendMessage()
        }

        let userInfo = HealthManager.shared.userInfoModel
        let viewModel = InsightsViewModel.shared
        let suggestions = await SleepProgramCoordinator.shared.sleepActivities

        let request = SleepCoachRequest(
            userInfo: .init(
                name: userInfo?.name,
                age: userInfo?.age,
                sex: userInfo?.sex,
                location: userInfo?.location
            ),
            sleepHealthSnapshot: SleepHealthSnapshot(
                timeInDaylight: viewModel.timeInDaylight,
                workouts: viewModel.workoutSummary,
                sleepSummaries: viewModel.sleepAnalysis,
                meditation: viewModel.meditationMinutes,
                restingHeartRate: viewModel.restingHeartRate
            ),
            currentSuggestions: suggestions,
            chatHistory: networkChatHistory
        )

        let response = try await NetworkRequester.shared.chatSleepCoach(request: request)

        await MainActor.run {
            var hasSentMessage = false
            var newChatHistory = chatHistory

            response.chatMessages?.forEach { chatMessage in
                newChatHistory.append(
                    ChatMessage(
                        message: chatMessage.message,
                        timestamp: .now,
                        isCurrentUser: false
                    )
                )
                unreadChatCount += 1
                hasSentMessage = true
            }

            chatHistory = newChatHistory

            if hasSentMessage {
                SoundPlayer.playReceiveMessage()
            }
        }
    }

    func sendProactiveTip() async {
        do {
            try await HealthManager.shared.loadUserInfo()
        } catch { print(error) }
        let userInfo = HealthManager.shared.userInfoModel
        let currentGoals = ProfileViewModel.shared.userGoals
        let currentSupplements = ProfileViewModel.shared.userSupplements

        let request = ProactiveTipRequestModel(
            userInfo: userInfo,
            currentSupplements: currentSupplements,
            currentGoals: currentGoals,
            chatHistory: networkChatHistory,
            learnedUserFacts: ProfileViewModel.shared.userFacts
        )

        do {
            let response = try await NetworkRequester.shared.sendProactiveTip(request: request)

            await MainActor.run {
                var newChatHistory = chatHistory

                newChatHistory.append(
                    ChatMessage(
                        message: response.message,
                        timestamp: .now,
                        supplementReccomendation: [],
                        activityRecommendation: [],
                        isCurrentUser: false
                    )
                )
                unreadChatCount += 1

                if let recommendations = response.recommendedActivities, recommendations.isNotEmpty {
                    newChatHistory.append(
                        ChatMessage(
                            message: nil,
                            timestamp: .now,
                            supplementReccomendation: [],
                            activityRecommendation: recommendations,
                            isCurrentUser: false
                        )
                    )
                    unreadChatCount += 1
                }

                chatHistory = newChatHistory

                SoundPlayer.playReceiveMessage()
            }

            await NotificationManager.shared.sendNotification(title: "Bloom", subtitle: response.message)
        } catch {
            print(error)
        }
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

        await NotificationManager.shared.sendNotification(title: "Bloom", subtitle: message)
    }

    func parseOnboardingInfo(chatHistory: [ChatMessage]) async {
        await MainActor.run {
            self.chatHistory = chatHistory
        }

        do {
            let request = OnboardingInfoRequest(chatHistory: networkChatHistory)
            let response = try await NetworkRequester.shared.parseOnboardingInfo(request: request)

            await MainActor.run {
                if let name = response.name {
                    ProfileViewModel.shared.name = name
                }
                ProfileViewModel.shared.userFacts = response.activities
                ProfileViewModel.shared.userSupplements = response.supplements
                ProfileViewModel.shared.userGoals = response.healthGoals
            }
        } catch {
            print(error)
        }
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
