//
//  OnboardingWelcomeView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI

struct OnboardingWelcomeView: View {
    var body: some View {
        Image(.bloomAppIcon)
            .resizable()
            .scaledToFit()
            .frame(width: 120)

        Text("Bloom")
            .font(.largeTitle)
            .bold()
            .fontDesign(.rounded)

        Text("Personal Health Assistant")
            .font(.title3)
            .bold()
            .fontDesign(.rounded)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    OnboardingWelcomeView()
}
