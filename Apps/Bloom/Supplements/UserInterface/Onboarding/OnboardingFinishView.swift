//
//  OnboardingFinishView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-31.
//

import SwiftUI
import AppUI

struct OnboardingFinishView: View {
    var onContinue: () -> Void

    @State private var index = 0
    @State private var didContinue = false

    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(.bloomAppIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                    .transition(.blurReplace)
                    .appear(with: 1, currentIndex: index, secondaryIfNotCurrentIndex: false)

                Text("We made it, \(healthManager.name)!")
                    .appear(with: 1, currentIndex: index)

                Text("Are you ready to get started?")
                    .multilineTextAlignment(.center)
                    .appear(with: 2, currentIndex: index)
            }
            .horizontallyCentered()
            .onboardingTextStyle()
            .padding()
        }
        .animation(.default, value: index)
        .sensoryFeedback(.selection, trigger: index)
        .sensoryFeedback(.selection, trigger: didContinue)
        .shelf {
            if index >= 2 {
                Button("Yes!") {
                    didContinue.toggle()
                    onContinue()
                }
                .buttonStyle(.onboarding)
            }
        }
        .task {
            while index < 2 {
                await advanceIndex()
            }
        }
    }
}

private extension OnboardingFinishView {

    func advanceIndex() async {
        await Delay(1700)

        index += 1
    }
}

#Preview {
    OnboardingFinishView { }
}
