//
//  OnboardingHealthKitView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-05-09.
//

import SwiftUI
import AppUI
import HealthKitUI

struct OnboardingHealthKitView: View {
    let onContinue: () -> Void

    @ObservedObject private var healthManager = HealthManager.shared

    @State private var healthPermissionTrigger = false

    var body: some View {
        OnboardingCardTemplateView {
            Image(.healthAppIcon)
                .resizable()
                .scaledToFit()
                .frame(square: 100)

            Text("Health App")
                .font(.largeTitle)
                .bold()

            Text("Bloom uses your data in the Health App to help give you recommendations. Data is organized into vitals which represent different areas of your overall health.")
                .font(.headline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: 300)
                .multilineTextAlignment(.center)
        } bottom: {
            ScrollView {
                VStack {
                    MonthlyVitalCardCell(
                        vital: .init(
                            id: .sleepQuality,
                            subtitle: "Avg 7h45min",
                            status: "Good",
                            score: 0.8,
                            color: .green,
                            trend: .decreasing
                        )
                    )

                    MonthlyVitalCardCell(
                        vital: .init(
                            id: .stressLevels,
                            subtitle: "BP: 121/78",
                            status: "Moderate",
                            score: 0.8,
                            color: .yellow,
                            trend: .decreasing
                        )
                    )

                    MonthlyVitalCardCell(
                        vital: .init(
                            id: .cardioFitness,
                            subtitle: "VO₂ Max: 43 mL/min·kg",
                            status: "Above Average",
                            score: 0.8,
                            color: .green,
                            trend: .increasing
                        )
                    )

                    MonthlyVitalCardCell(
                        vital: .init(
                            id: .nutrition,
                            subtitle: "Slight Energy Deficiency",
                            status: "Very Healthy",
                            score: 0.8,
                            color: .blue,
                            trend: .increasing
                        )
                    )

                    MonthlyVitalCardCell(
                        vital: .init(
                            id: .activityLevel,
                            subtitle: "1796 Cal Basal\n241 Cal Active",
                            status: "Light",
                            score: 0.8,
                            color: .green,
                            trend: .increasing
                        )
                    )

                    MonthlyVitalCardCell(
                        vital: .init(
                            id: .bodyComposition,
                            subtitle: "19% Body Fat",
                            status: "Healthy",
                            score: 0.8,
                            color: .green,
                            trend: .decreasing
                        )
                    )
                }
                .padding()
            }
        }
        .shelf {
            VStack {
                ProminentButton("Continue") {
                    onContinue()
                }
//                Text("Bloom is not a substitute for professional medical advice. Always consult your physician first.")
//                    .multilineTextAlignment(.center)
//                    .foregroundStyle(.secondary)
//                    .font(.caption)
            }
        }
    }
}

#Preview {
    OnboardingHealthKitView { }
}
