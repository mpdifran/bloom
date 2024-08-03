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
        do {
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
                Delay(100) {
                    self.isWaitingForResponse = true
                }
            }

            let viewModel = InsightsViewModel.shared
            let suggestions = await SleepProgramCoordinator.shared.sleepActivities

            let location: LocationModel?
            if let currentLocation = LocationManager.shared.currentLocation {
                location = .init(
                    latitude: currentLocation.coordinate.latitude,
                    longitude: currentLocation.coordinate.longitude
                )
            } else {
                location = nil
            }

            let request = SleepCoachRequest(
                userInfo: .init(
                    name: ProfileViewModel.shared.name,
                    age: HealthManager.shared.age(),
                    sex: HealthManager.shared.sexName(),
                    location: location
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

                SleepProgramCoordinator.shared.sleepActivities = response.suggestions

                if hasSentMessage {
                    SoundPlayer.playReceiveMessage()
                }

                Delay(100) {
                    self.isWaitingForResponse = false
                }
            }
        } catch {
            await MainActor.run {
                Delay(100) {
                    self.isWaitingForResponse = false
                }
            }

            throw error
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

        await NotificationManager.shared.sendNotification(
            title: "Bloom",
            subtitle: message,
            categoryID: .CategoryID.chatMessage
        )
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
