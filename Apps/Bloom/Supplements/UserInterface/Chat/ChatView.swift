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
    @State private var presentedSheet: AnyView?
    @State private var confirmationDialog: ConfirmationDialogDetails?
    @State private var error: Error?

    @ObservedObject private var viewModel = ChatViewModel.shared
    @ObservedObject private var healthManager = HealthManager.shared

    @Environment(TabController.self) private var tabController: TabController

    @AppStorage("PreferencesView.danieleMode") private var danieleMode = false

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollViewProxy in
                Group {
                    if viewModel.chatHistory.isEmpty {
                        ContentUnavailableView(label: {
                            Label(
                                title: {
                                    Text("Ask Bloom about your health")
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
                                    }
                                }

                                if viewModel.isWaitingForResponse {
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

                    if danieleMode {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Proactive Tip", systemImage: "sparkles") {
                                Task {
                                    await ProactiveTipper.shared.sendProactiveTip()
                                }
                            }
                        }
                    }
                }
                .onChange(of: viewModel.chatHistory.count) { _, _ in
                    scrollViewProxy.scrollTo(viewModel.lastID(), anchor: .bottom)

//                    if tabController.activeTab == .chat {
//                        viewModel.unreadChatCount = 0
//                    }
                }
                .onAppear {
                    scrollViewProxy.scrollTo(viewModel.lastID(), anchor: .bottom)
                }
                .onChange(of: viewModel.chatHistory.count) { (_, _) in
                    Delay(300) {
                        MainTask {
                            scrollViewProxy.scrollTo(viewModel.lastID(), anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isWaitingForResponse) { (_, _) in
                    Delay(300) {
                        scrollViewProxy.scrollTo("TypingPrompt", anchor: .bottom)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                ChatBar(text: $searchText) {
                    submitPrompt()
                }
                .padding()
            }
            .navigationTitle("Chat")
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
            do {
                let prompt = searchText
                searchText = ""
                feedbackGenerator.impactOccurred()
                try await viewModel.send(prompt: prompt)
            } catch {
                self.error = error
            }
        }
    }
}

#Preview {
    TabView {
        ChatView()
    }
}
