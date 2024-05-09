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

    @FocusState private var isSearchFieldFocused: Bool

    @ObservedObject private var viewModel = ChatViewModel.shared
    @ObservedObject private var healthManager = HealthManager.shared

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollViewProxy in
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
                HStack {
                    Image(systemName: "magnifyingglass")
                        .bold()
                        .fontDesign(.rounded)

                    TextField(
                        "",
                        text: $searchText,
                        prompt: Text("How can I help you?"),
                        axis: .vertical
                    )
                    .focused($isSearchFieldFocused)
                    .font(.title3)
                    .fontDesign(.rounded)
                    .bold()
                    .submitLabel(.send)
                    .onChange(of: searchText) { oldValue, newValue in
                        if let newLineIndex = newValue.lastIndex(of: "\n") {
                            searchText.remove(at: newLineIndex)
                            isSearchFieldFocused = false
                            submitPrompt()
                        }
                    }
                }
                .padding(.vertical, 8)
                .roundedBackground()
            }
            .navigationTitle("Vitadex")
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
