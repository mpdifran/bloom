//
//  OnboardingTitleCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SwiftUI

struct OnboardingTitleCardView: View {
    let systemImage: String
    let title: String
    let message: String

    init(
        systemImage: String = "hand.raised.circle.fill",
        title: String,
        message: String
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
    }

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: systemImage)
                .foregroundStyle(.white, .tint)
                .font(.system(size: 80))
            Text(title)
                .font(.largeTitle)
                .bold()
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    OnboardingTitleCardView(
        title: "Age & Sex",
        message: "This is a message about health data."
    )
}
