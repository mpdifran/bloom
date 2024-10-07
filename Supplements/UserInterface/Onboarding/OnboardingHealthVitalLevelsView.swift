//
//  OnboardingHealthVitalLevelsView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-15.
//

import SwiftUI
import AppUI
import DataContainer

struct OnboardingHealthVitalLevelsView: View {
    let onContinue: () -> Void

    @ObservedObject private var vitalsViewModel = VitalsViewModel.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Vitals")
                    .font(.largeTitle)
                    .bold()
                    .fontDesign(.rounded)

                Text("Bloom organizes your health data into several categories, called **Vitals**.")

                ForEach(vitalsViewModel.vitals) { vital in
                    MonthlyVitalCardCell(vital: vital)
                }

                Text("Levels")
                    .font(.largeTitle)
                    .bold()
                    .fontDesign(.rounded)

                Text("Each **Vital** is categorized into different color-coded levels based on where your health data falls in recommended ranges.")

                VitalLevelView(
                    systemImage: "checkmark.seal.fill",
                    title: "Great",
                    description: "You're exceeding recommended health levels."
                )
                .tint(.vitalGreat)
                VitalLevelView(
                    systemImage: "checkmark.circle.fill",
                    title: "Good",
                    description: "You're at the recommended healthy level."
                )
                .tint(.vitalGood)
                VitalLevelView(
                    systemImage: "exclamationmark.triangle.fill",
                    title: "Low",
                    description: "You're below recommended health levels, and should take notice."
                )
                .tint(.vitalWarning)
                VitalLevelView(
                    systemImage: "exclamationmark.octagon.fill",
                    title: "Poor",
                    description: "You're outside recommended health levels, and should take action ASAP."
                )
                .tint(.vitalSevere)
            }
            .padding()
        }
        .shelf {
            ProminentButton("Continue") {
                onContinue()
            }
        }
        .groupedBackground()
        .safeAreaInset(edge: .top) {
            Rectangle()
                .fill(.bar)
                .ignoresSafeArea()
                .frame(height: 0)
        }
        .task {
            await vitalsViewModel.forceFetchVitals()
        }
    }
}

private struct MiniVitalView: View {
    let kind: VitalModel.Kind

    var body: some View {
        HStack {
            Image(systemName: kind.systemImage)
                .font(.subheadline)
                .bold()

            Text(kind.name)
                .font(.headline)

            Spacer()
        }
        .cardContainer(fill: .background.secondary)
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
