    //
//  ContentView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-03-21.
//

import SwiftUI
import AppUI

@MainActor
struct ContentView: View {

    @AppStorage("hasShownOnboarding") var hasShownOnboarding: Bool = false

    @State private var searchText = ""
    @State private var presentedNavigationView: AnyView?
    @State private var bodyWeight: Double?
    @State private var presentedSheet: AnyView?
    @State private var error: Error?

    @ObservedObject private var viewModel = ChatViewModel.shared
    @ObservedObject private var healthManager = HealthManager.shared

    let feedbackGenerator = UIImpactFeedbackGenerator(style: .soft)

    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(viewModel.chatHistory) { chatMessage in
                    ChatBubbleCell(
                        message: chatMessage.message,
                        isDirect: false,
                        isCurrentUser: chatMessage.isCurrentUser,
                        showTail: true
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Show Onboarding", systemImage: "rectangle.portrait.and.arrow.right") {
                        checkOnboarding(force: true)
                    }
                }
            }
            .shelf {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .bold()
                        .fontDesign(.rounded)

                    TextField("", text: $searchText, prompt: Text("How can I help you?"))
                        .font(.title3)
                        .fontDesign(.rounded)
                        .bold()
                        .submitLabel(.go)
                        .onSubmit {
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
                .padding(.vertical, 8)
                .roundedBackground()
            }
            .navigationTitle("Vitadex")
            .navigationDestination($presentedNavigationView)
        }
        .sheet($presentedSheet)
        .alert(error: $error)
        .onAppear {
            checkOnboarding()
            feedbackGenerator.prepare()
        }
        .animation(.bouncy, value: viewModel.chatHistory.count)
        .onChange(of: healthManager.isAuthorized) { oldValue, newValue in
            guard newValue else { return }

            Task {
                if let bodyWeight = await healthManager.fetchBodyWeight() {
                    self.bodyWeight = bodyWeight.quantity.doubleValue(for: .pound())
                }

            }
        }
    }
}

private extension ContentView {

    func checkOnboarding(force: Bool = false) {
        if force {
            hasShownOnboarding = false
        }

        guard !hasShownOnboarding else { return }

        presentedSheet = OnboardingRootView(onComplete: {
            hasShownOnboarding = true
        }).asAny
    }
}

#Preview {
    ContentView()
}
