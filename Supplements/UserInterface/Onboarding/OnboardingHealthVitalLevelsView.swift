//
//  OnboardingHealthVitalLevelsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SwiftUI
import AppUI

struct OnboardingHealthVitalLevelsView: View {
    let onContinue: () -> Void

    var body: some View {
        ScrollView {
            VStack {
                Text("Vital Levels")
                    .font(.largeTitle)
                    .bold()
                    .fontDesign(.rounded)

                VitalLevelView(
                    systemImage: "checkmark.seal.fill",
                    title: "Great",
                    description: "You're exceeding recommended health levels."
                )
                .tint(.blue)
                VitalLevelView(
                    systemImage: "checkmark.circle.fill",
                    title: "Good",
                    description: "You're at the recommended healthy level."
                )
                .tint(.green)
                VitalLevelView(
                    systemImage: "exclamationmark.triangle.fill",
                    title: "Low",
                    description: "You're below recommended health levels, and should take notice."
                )
                .tint(.yellow)
                VitalLevelView(
                    systemImage: "exclamationmark.octagon.fill",
                    title: "Poor",
                    description: "You're at a dangerous health level, and should take action immediately."
                )
                .tint(.pink)
            }
            .padding()
        }
        .shelf {
            ProminentButton("Continue") {
                onContinue()
            }
        }
    }
}

private struct VitalLevelView: View {
    let systemImage: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: systemImage)
                .font(.title)
                .bold()
                .foregroundStyle(.white, .tint)

            VStack(alignment: .leading) {
                Text(title)
                    .font(.title3)
                    .bold()

                Text(description)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .cardContainer(fill: .background.secondary)
    }
}

#Preview {
    OnboardingHealthVitalLevelsView { }
}
