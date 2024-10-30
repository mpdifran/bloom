//
//  OnboardingWelcomeView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import AppUI
import TelemetryDeck

struct OnboardingWelcomeView: View {
    var onContinue: () -> Void

    @State private var index = 1
    @State private var didContinue = false

    @FocusState private var isFocused: Bool

    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(.bloomAppIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)

                Text("Hey there!")
                    .appear(with: 1, currentIndex: index)

                Text("Welcome to Bloom, your new personal Health Assistant")
                    .transition(.opacity)
                    .appear(with: 2, currentIndex: index)

                Group {
                    Text("What should we call you?")

                    TextField("", text: $healthManager.name, prompt: Text("Your Name"))
                        .textContentType(.name)
                        .cardContainer(fill: .background.secondary)
                        .focused($isFocused)
                        .submitLabel(.continue)
                        .disabled(index != 3)
                        .onSubmit {
                            index += 1
                        }
                        .onAppear {
                            isFocused = true
                        }
                }
                .transition(.blurReplace)
                .appear(with: 3, currentIndex: index)


                Text("Nice to meet you, \(healthManager.name)! Let's get to know each other a bit...")
                    .transition(.opacity)
                    .appear(with: 4, currentIndex: index)

                Spacer()
            }
            .padding()
            .horizontalAlignment(.leading)
        }
        .onboardingTextStyle()
        .topSafeAreaBlur()
        .sensoryFeedback(.selection, trigger: index)
        .sensoryFeedback(.selection, trigger: didContinue)
        .animation(.default, value: index)
        .if(index >= 4) {
            $0.shelf {
                Button("Sounds great!") {
                    didContinue.toggle()
                    onContinue()
                }
                .buttonStyle(.onboarding)
            }
        }
        .task {
            while index < 3 {
                await advanceIndex()
            }
        }
        .onAppear {
            TelemetryDeck.signal("OB Welcome")
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
