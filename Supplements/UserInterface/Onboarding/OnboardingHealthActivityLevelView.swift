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

    @State private var vitalsViewModel = VitalsViewModel.shared

    @State private var index = 0
    @State private var activityLevels = [ActivityLevelSummary.ActivityLevel]()
    @State private var didContinue = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Your activity level is an important factor in your health.")
                        .transition(.opacity)
                        .appear(with: 1, currentIndex: index)

                    if vitalsViewModel.activityLevelSummary?.details.activityLevel != nil {
                        Text("We've selected where we think your activity level is based on your Health data, but feel free to change it!")
                            .font(.title3)
                            .transition(.opacity)
                            .appear(with: 2, currentIndex: index)
                    } else {
                        Text("Select the level you identify with the most.")
                            .font(.title3)
                            .transition(.opacity)
                            .appear(with: 2, currentIndex: index)
                    }
                }
                .onboardingTextStyle()

                VStack {
                    ForEach(activityLevels) { activityLevel in
                        ActivityLevelSelectionCell(
                            activityLevel: activityLevel,
                            isRecommended: vitalsViewModel.activityLevelSummary?.details.activityLevel == activityLevel,
                            isSelected: healthManager.userReportedActivityLevel == activityLevel
                        )
                        .transition(.scale)
                        .onTapGesture {
                            healthManager.userReportedActivityLevel = activityLevel
                        }
                    }
                }
            }
            .horizontalAlignment(.leading)
            .padding()
        }
        .animation(.default, value: index)
        .animation(.bouncy, value: activityLevels.count)
        .animation(.default, value: healthManager.userReportedActivityLevel)
        .sensoryFeedback(.selection, trigger: index)
        .sensoryFeedback(.selection, trigger: activityLevels.count)
        .sensoryFeedback(.impact, trigger: healthManager.userReportedActivityLevel)
        .sensoryFeedback(.selection, trigger: didContinue)
        .onAppear {
            healthManager.userReportedActivityLevel = vitalsViewModel.activityLevelSummary?.details.activityLevel
        }
        .task {
            while index < 2 {
                await advanceIndex()
            }

            await Delay(500)

            await addActivityLevels()
        }
        .shelf {
            Button("That looks right") {
                didContinue.toggle()
                onContinue()
            }
            .buttonStyle(.onboarding)
            .disabled(healthManager.userReportedActivityLevel == nil)
        }
    }
}

private extension OnboardingHealthActivityLevelView {

    func advanceIndex() async {
        await Delay(1700)

        index += 1
    }

    func addActivityLevels() async {
        await Delay(100)

        if activityLevels.count < ActivityLevelSummary.ActivityLevel.allCases.count {
            let index = activityLevels.count

            activityLevels.append(ActivityLevelSummary.ActivityLevel.allCases[index])
        } else {
            return
        }

        await addActivityLevels()
    }
}

#Preview {
    OnboardingHealthActivityLevelView { }
}
