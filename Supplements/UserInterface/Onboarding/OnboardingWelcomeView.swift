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

    var body: some View {
        VStack {
            Spacer()

            Image(.bloomAppIcon)
                .resizable()
                .scaledToFit()
                .frame(width: 120)

            Text("Bloom")
                .font(.largeTitle)
                .bold()
                .fontDesign(.rounded)

            Text("Welcome to Bloom, your new personal health assistant.")
                .font(.title3)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)

            Spacer()
        }
        .shelf {
            ProminentButton("Continue") {
                onContinue()
            }
            .buttonBorderShape(.roundedRectangle(radius: 17))
        }
    }
}

#Preview {
    OnboardingWelcomeView { }
}
