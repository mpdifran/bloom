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
    @State private var error: Error?

    @ObservedObject private var viewModel = ChatViewModel.shared
    @ObservedObject private var healthManager = HealthManager.shared

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
                                        .foregroundStyle(.tint)
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
                                        ForEach(chatMessage.supplementReccomendation) { reccomendation in
                                            SupplementBubble(supplementReccomendation: reccomendation)
                                                .id(reccomendation.id)
                                        }
                                    }
                                }

                                if isWaitingForResponse {
                                    TypingIndicatorCell(isDirect: false)
                                        .id("TypingPrompt")
                                        .padding(.bottom, 12)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Proactive Tip", systemImage: "rectangle.portrait.and.arrow.right") {
                            Task {
                                await viewModel.sendProactiveTip()
                            }
                        }
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
                    systemImage: "magnifyingglass",
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
        }
        .animation(.default, value: viewModel.chatHistory.count)
        .tabItem {
            Label("Chat", systemImage: "bubble")
        }
    }
}

private extension ChatView {

    func submitPrompt() {
        Task {
            await MainActor.run {
                isWaitingForResponse = true
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
                isWaitingForResponse = false
            }
        }
    }
}

#Preview {
    ChatView()
}
