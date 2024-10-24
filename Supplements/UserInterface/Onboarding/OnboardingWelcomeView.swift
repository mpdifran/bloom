//
//  OnboardingWelcomeView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import AppUI

struct OnboardingWelcomeView: View {
    var onContinue: () -> Void

    @State private var index = 1

    @FocusState private var isFocused: Bool

    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(.bloomAppIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)

                if index >= 1 {
                    Text("Hey there!")
                        .contentTransition(.interpolate)
                        .if(index != 1) {
                            $0.foregroundStyle(.secondary)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                }

                if index >= 2 {
                    Text("Welcome to Bloom, your new personal Health Assistant")
                        .contentTransition(.interpolate)
                        .if(index != 2) {
                            $0.foregroundStyle(.secondary)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }

                if index >= 3 {
                    Text("What should we call you?")
                        .if(index != 3) {
                            $0.foregroundStyle(.secondary)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.blurReplace)

                    TextField("", text: $healthManager.name, prompt: Text("Your Name"))
                        .textContentType(.name)
                        .cardContainer(fill: .background.secondary)
                        .focused($isFocused)
                        .submitLabel(.continue)
                        .disabled(index != 3)
                        .onSubmit {
                            index += 1
                            Task {
                                await advanceIndex()
                            }
                        }
                        .onAppear {
                            isFocused = true
                        }
                        .transition(.blurReplace)
                }

                if index >= 4 {
                    Text("Nice to meet you, \(healthManager.name)! Let's get to know each other a bit...")
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.blurReplace)
                }

                Spacer()
            }
            .horizontalAlignment(.leading)
        }
        .font(.title)
        .bold()
        .fontDesign(.rounded)
        .padding()
        .sensoryFeedback(.selection, trigger: index)
        .animation(.default, value: index)
        .shelf {
            if index >= 5 {
                Button("Continue") {
                    onContinue()
                }
                .buttonStyle(.onboarding)
                .transition(.move(edge: .bottom))
            }
        }
        .task {
            while index < 3 {
                await advanceIndex()
            }
        }
    }
}

private extension OnboardingWelcomeView {

    func advanceIndex() async {
        await Delay(1700)

        index += 1
    }
}

#Preview {
    OnboardingWelcomeView { }
}
