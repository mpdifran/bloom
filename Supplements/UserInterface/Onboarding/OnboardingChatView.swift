//
//  OnboardingChatView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-21.
//

import SwiftUI
import AppFoundations

struct OnboardingChatView: View {
    
    var onComplete: ([ChatMessage]) -> Void

    @ObservedObject private var supplementsViewModel = SupplementViewModel.shared
    @ObservedObject private var goalsViewModel = GoalViewModel.shared
    @ObservedObject private var healthManager = HealthManager.shared

    @State private var chatMessages = [ChatMessage]()
    @State private var isWaitingForResponse = false
    @State private var userCanSendMessage = false
    @FocusState private var isSendFieldFocused
    @State private var userMessage = ""
    @State private var hasPromptedForHealthKit = false

    @State private var onboardingMessages: ChatMessageGroup?
    @State private var onboardingMessageGroups: [ChatMessageGroup] = [
        ChatMessageGroup(
            chatMessages: [
                ChatMessage(message: "Hi, welcome to Bloom! I'm your personal AI health assistant.", timestamp: .now, supplementReccomendation: [], isCurrentUser: false),
                ChatMessage(message: "I'd love to get to know you better.", timestamp: .now, supplementReccomendation: [], isCurrentUser: false),
                ChatMessage(message: "What's your name?", timestamp: .now, supplementReccomendation: [], isCurrentUser: false),
            ],
            step: .textInput
        ),
        ChatMessageGroup(
            chatMessages: [
                ChatMessage(message: "Nice to meet you!", timestamp: .now, supplementReccomendation: [], isCurrentUser: false),
                ChatMessage(message: "In order to get a better view of your health, I'll need to have access to your health data.", timestamp: .now, supplementReccomendation: [], isCurrentUser: false),
                ChatMessage(message: "Let me know what you'd like to share!", timestamp: .now, supplementReccomendation: [], isCurrentUser: false),
            ],
            step: .healthKit
        ),
        ChatMessageGroup(
            chatMessages: [
                ChatMessage(message: "Great! Let's learn more about your preferences.", timestamp: .now, supplementReccomendation: [], isCurrentUser: false),
                ChatMessage(message: "What do you like to do to stay active?", timestamp: .now, supplementReccomendation: [], isCurrentUser: false)
            ],
            step: .textInput
        ),
        ChatMessageGroup(
            chatMessages: [
                ChatMessage(message: "Cool!", timestamp: .now, supplementReccomendation: [], isCurrentUser: false),
                ChatMessage(message: "Are you currently taking any supplements? If so, please list them.", timestamp: .now, supplementReccomendation: [], isCurrentUser: false)
            ],
            step: .textInput
        ),
        ChatMessageGroup(
            chatMessages: [
                ChatMessage(message: "Nice. What about your health goals? What would you like to achieve?", timestamp: .now, supplementReccomendation: [], isCurrentUser: false)
            ],
            step: .textInput
        ),
        ChatMessageGroup(
            chatMessages: [
                ChatMessage(message: "Great, that should be enough to get started. Welcome to Bloom!", timestamp: .now, supplementReccomendation: [], isCurrentUser: false)
            ],
            step: .finish
        ),
    ]

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollViewProxy in
                ScrollView {
                    LazyVStack {
                        ForEach(chatMessages) { chatMessage in
                            if let message = chatMessage.message {
                                ChatBubbleCell(
                                    message: message,
                                    isDirect: false,
                                    isCurrentUser: chatMessage.isCurrentUser,
                                    showTail: true
                                )
                                .id(chatMessage.id)
                            }
                        }

                        if isWaitingForResponse {
                            TypingIndicatorCell(isDirect: false)
                                .padding(.bottom, 12)
                                .id("TypingPrompt")
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: chatMessages.count) { (_, _) in
                    if let id = chatMessages.last?.id {
                        Delay(300) {
                            scrollViewProxy.scrollTo(id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: isWaitingForResponse) { (_, _) in
                    Delay(300) {
                        scrollViewProxy.scrollTo("TypingPrompt", anchor: .bottom)
                    }
                }
            }
            .navigationTitle("Bloom")
            .shelf {
                TextActionBar(
                    searchText: $userMessage,
                    prompt: "",
                    systemImage: "bolt.heart.fill",
                    axis: .vertical,
                    submitLabel: .send
                ) {
                    recordUserMessage()
                }
                .focused($isSendFieldFocused)
                .disabled(!userCanSendMessage)
            }
        }
        .onChange(of: HealthManager.shared.isAuthorized, { _, newValue in
            if newValue && hasPromptedForHealthKit {
                sendNextGroupOfMessages()
            }
        })
        .animation(.bouncy, value: chatMessages.count)
        .onAppear {
            isWaitingForResponse = true
            Delay(4000) {
                sendNextGroupOfMessages()
            }
        }
    }
}

extension OnboardingChatView {

    func sendNextGroupOfMessages() {
        guard onboardingMessageGroups.isNotEmpty else {
            // We've finished the onboarding
            onComplete(chatMessages)
            return
        }

        var nextGroup = onboardingMessageGroups.remove(at: 0)

        if nextGroup.step == .healthKit && HealthManager.shared.isAuthorized {
            nextGroup = onboardingMessageGroups.remove(at: 0)
        }

        onboardingMessages = nextGroup
        sendNextMessage()
    }

    func sendNextMessage() {
        isWaitingForResponse = false

        guard onboardingMessages?.chatMessages.isNotEmpty == true else {
            handleEndOfAssistantGroupMessages()
            return
        }

        if let message = onboardingMessages?.chatMessages.remove(at: 0) {
            chatMessages.append(message)
        }

        guard onboardingMessages?.chatMessages.isNotEmpty == true else {
            handleEndOfAssistantGroupMessages()
            return
        }

        Delay(300) {
            isWaitingForResponse = true
        }

        Delay(2500) {
            sendNextMessage()
        }
    }

    func handleEndOfAssistantGroupMessages() {
        guard let messageGroup = onboardingMessages else { fatalError("Whoopsie") }

        switch messageGroup.step {
        case .healthKit:
            hasPromptedForHealthKit = true
            Task {
                await HealthManager.shared.requestAccess()
            }
        case .textInput:
            userCanSendMessage = true
            isSendFieldFocused = true
        case .finish:
            Delay(3000) {
                onComplete(chatMessages)
            }
        }
    }

    func recordUserMessage() {
        guard userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty else {
            return
        }

        let message = ChatMessage(
            message: userMessage.trimmingCharacters(in: .whitespacesAndNewlines),
            timestamp: .now,
            supplementReccomendation: [],
            isCurrentUser: true
        )
        chatMessages.append(message)

        userMessage = ""
        userCanSendMessage = false
        isSendFieldFocused = false

        Delay(1500) {
            isWaitingForResponse = true
        }

        Delay(2500) {
            sendNextGroupOfMessages()
        }
    }
}

struct ChatMessageGroup {
    var chatMessages: [ChatMessage]
    var step: Step
}

extension ChatMessageGroup {
    enum Step {
        case healthKit
        case textInput
        case finish
    }
}

#Preview {
    OnboardingChatView { _ in }
}
