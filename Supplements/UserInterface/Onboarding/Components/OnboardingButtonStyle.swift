//
//  OnboardingButtonStyle.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-24.
//

import SwiftUI

struct OnboardingButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            configuration.label
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .font(.headline)
        .fontDesign(.rounded)
        .bold()
        .padding(.vertical, 20)
        .background {
            RoundedRectangle(cornerRadius: 26)
                .fill(.tint)
        }
    }
}

extension ButtonStyle where Self == OnboardingButtonStyle {
    static var onboarding: some ButtonStyle { OnboardingButtonStyle() }
}

#Preview {
    Button("Onboarding") {

    }
    .buttonStyle(.onboarding)
    .padding()
}
