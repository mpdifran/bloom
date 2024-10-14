//
//  OnboardingHealthActivityLevelView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-14.
//

import SwiftUI
import AppUI

struct OnboardingHealthActivityLevelView: View {
    let onContinue: () -> Void

    @ObservedObject private var healthManager = HealthManager.shared

    var userSelectableActivityLevels: [ActivityLevelSummary.ActivityLevel] = [
        .sedentary,
        .light,
        .high
    ]

    var body: some View {
        OnboardingCardTemplateView(aspectRatio: 1.3) {
            OnboardingTitleCardView(
                title: "Activity Level",
                message: "Bloom uses your activity level to help set your goals."
            )
        } bottom: {
            ScrollView {
                VStack {
                    ActivityLevelSelectionCell(
                        isSelected: healthManager.userReportedActivityLevel == .sedentary,
                        title: "Sedentary",
                        subtitle: "Little to no exercise",
                        systemImage: "figure.stand"
                    )
                    .tint(.vitalWarning)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        healthManager.userReportedActivityLevel = .sedentary
                    }

                    ActivityLevelSelectionCell(
                        isSelected: healthManager.userReportedActivityLevel == .light,
                        title: "Light",
                        subtitle: "Exercise 1 to 3 times a week",
                        systemImage: "figure.run"
                    )
                    .tint(.vitalGood)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        healthManager.userReportedActivityLevel = .light
                    }

                    ActivityLevelSelectionCell(
                        isSelected: healthManager.userReportedActivityLevel == .high,
                        title: "High",
                        subtitle: "Exercise 4 to 7 times a week",
                        systemImage: "figure.tennis"
                    )
                    .tint(.vitalGreat)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        healthManager.userReportedActivityLevel = .high
                    }
                }
                .padding()
            }
        }
        .shelf {
            ProminentButton("Continue") {
                onContinue()
            }
            .disabled(healthManager.userReportedActivityLevel == nil)
        }
    }
}

struct ActivityLevelSelectionCell: View {
    let isSelected: Bool

    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .font(.largeTitle)
                .frame(width: 40)

            VStack(alignment: .leading) {
                Text(title)

                Text(subtitle)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white, .tint)
                    .font(.title2)
                    .bold()
            }
        }
        .cardContainer()
    }
}

#Preview {
    OnboardingHealthActivityLevelView { }
}
