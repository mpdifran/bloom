//
//  OnboardingHealthKitView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import AppUI

struct OnboardingHealthKitView: View {

    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        VStack {
            Spacer()

            Image(.healthAppIcon)
                .resizable()
                .scaledToFit()
                .frame(square: 100)

            Text("Health App")
                .font(.largeTitle)
                .bold()

            Text("Link your Health data to help Bloom give you better recommendations.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 300)
                .multilineTextAlignment(.center)

            Spacer()

            Spacer()

            Spacer()
        }
        .fontDesign(.rounded)
        .shelf {
            VStack {
                ProminentButton("Connect to Health", systemImage: "heart.fill") {
                    Task {
                        await healthManager.requestAccessIfNeeded()
                    }
                }
                .buttonBorderShape(.roundedRectangle(radius: 17))
                Text("Bloom is not a substitute for professional medical advice. Always consult your physician first.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    OnboardingHealthKitView()
}
