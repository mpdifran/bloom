    //
//  ChatView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-03-21.
//

import SwiftUI
import AppUI

@MainActor
struct ChatView: View {

    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false

    @State private var searchText = ""
    @State private var isWaitingForResponse = false
    @State private var presentedSheet: AnyView?
    @State private var confirmationDialog: ConfirmationDialogDetails?
    @State private var error: Error?

    @ObservedObject private var viewModel = ChatViewModel.shared
    @ObservedObject private var healthManager = HealthManager.shared

    @EnvironmentObject private var tabContorller: TabController

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollViewProxy in
                Group {
                    if viewModel.chatHistory.isEmpty {
                        ContentUnavailableView(label: {
                            Label(
                                title: {
                                    Text("Ask Bloom anything about your health")
                                },
                                icon: {
                                    Image(systemName: "bolt.heart.fill")
                                        .foregroundStyle(.white, .tint)
                                }
                            )
                        })
                    } else {
                        ScrollView {
                            LazyVStack {
                                ForEach(viewModel.chatHistory) { chatMessage in
                                    if let message = chatMessage.message {
                                        ChatBubbleCell(
                                            message: message,
                                            isDirect: false,
                                            isCurrentUser: chatMessage.isCurrentUser,
                                            showTail: true
                                        )
                                        .id(chatMessage.id)
                                    } else {
                                        ForEach(chatMessage.supplementReccomendation) { recommendation in
                                            SupplementBubble(supplementReccomendation: recommendation)
                                                .id(recommendation.id)
                                        }
                                        ForEach(chatMessage.activityRecommendation) { recommendation in
                                            ActivityBubbleCell(activityModel: recommendation)
                                                .id(recommendation.id)
                                        }
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
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Delete Chat History", systemImage: "trash") {
                            confirmationDialog = .init(
                                title: "Are You Sure?",
                                message: "This will permanently erase your chat history with Bloom.",
                                buttons: [
                                    .init(title: "Delete", role: .destructive) {
                                        viewModel.deleteChatHistory()
                                    }
                                ]
                            )
                        }
                        .confirmationDialog($confirmationDialog)
                    }
                }
                .onChange(of: viewModel.chatHistory.count) { _, _ in
                    scrollViewProxy.scrollTo(viewModel.lastID(), anchor: .bottom)

                    if tabContorller.activeTab == .chat {
                        viewModel.unreadChatCount = 0
                    }
                }
                .onAppear {
                    scrollViewProxy.scrollTo(viewModel.lastID(), anchor: .bottom)
                }
                .onChange(of: viewModel.chatHistory.count) { (_, _) in
                    Delay(300) {
                        scrollViewProxy.scrollTo(viewModel.lastID(), anchor: .bottom)
                    }
                }
                .onChange(of: isWaitingForResponse) { (_, _) in
                    Delay(300) {
                        scrollViewProxy.scrollTo("TypingPrompt", anchor: .bottom)
                    }
                }
            }
            .shelf {
                TextActionBar(
                    searchText: $searchText,
                    prompt: "How can I help you?",
                    systemImage: "bolt.heart.fill",
                    axis: .vertical,
                    submitLabel: .send
                ) {
                    submitPrompt()
                }
            }
            .navigationTitle("Bloom")
        }
        .sheet($presentedSheet)
        .alert(error: $error)
        .onAppear {
            feedbackGenerator.prepare()
            viewModel.unreadChatCount = 0
        }
        .animation(.default, value: viewModel.chatHistory.count)
        .tabItem {
            Label("Chat", systemImage: "bubble")
        }
        .badge(viewModel.unreadChatCount)
    }
}

private extension ChatView {

    func submitPrompt() {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty else { return }

        Task {
            await MainActor.run {
                Delay(100) {
                    isWaitingForResponse = true
                }
            }

            do {
                let prompt = searchText
                searchText = ""
                feedbackGenerator.impactOccurred()
                try await viewModel.send(prompt: prompt)
            } catch {
                self.error = error
            }

            await MainActor.run {
                Delay(100) {
                    isWaitingForResponse = false
                }
            }
        }
    }
}

#Preview {
    TabView {
        ChatView()
    }
}
