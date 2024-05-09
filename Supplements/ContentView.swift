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

    @State private var searchText = ""
    @State private var presentedNavigationView: AnyView?
    @State private var bodyWeight: Double?
    @State private var error: Error?

    @ObservedObject private var viewModel = ChatViewModel.shared
    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                healthKitStatus
                weightStatus

                ForEach(viewModel.chatHistory) { chatMessage in
                    ChatBubbleCell(
                        message: chatMessage.message,
                        isDirect: false,
                        isCurrentUser: chatMessage.isCurrentUser,
                        showTail: true
                    )
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
                                    try await viewModel.send(prompt: searchText)
                                    searchText = ""
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
        .alert(error: $error)
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

    @ViewBuilder
    var healthKitStatus: some View {
        if !healthManager.isAuthorized {
            ChatBubbleCell(
                message: "Tap to link HealthKit",
                isDirect: true,
                isCurrentUser: false,
                showTail: false
            )
            .onTapGesture {
                Task {
                    await healthManager.requestAccess()
                }
            }
        } else {
            ChatBubbleCell(
                message: "HealthKit linked",
                isDirect: true,
                isCurrentUser: false,
                showTail: false
            )
        }
    }

    @ViewBuilder
    var weightStatus: some View {
        if let bodyWeight {
            ChatBubbleCell(
                message: "Body Weight: \(String(format: "%.0f", bodyWeight)) lbs",
                isDirect: true,
                isCurrentUser: false,
                showTail: false
            )
        }
    }
}

#Preview {
    ContentView()
}
