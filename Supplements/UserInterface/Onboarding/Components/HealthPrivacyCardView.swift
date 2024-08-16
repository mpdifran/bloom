//
//  HealthPrivacyCardView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SwiftUI

struct HealthPrivacyCardView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 15) {
            Image(systemName: "hand.raised.circle.fill")
                .foregroundStyle(.white, .blue)
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
    HealthPrivacyCardView(
        title: "Age & Sex",
        message: "This is a message about health data."
    )
}
