//
//  OnboardingHealthGoalView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-13.
//

import SwiftUI
import AppUI

struct OnboardingHealthGoalView: View {
    let onContinue: () -> Void

    @ObservedObject private var healthManager = HealthManager.shared

    var body: some View {
        OnboardingCardTemplateView(aspectRatio: 1.5) {
            OnboardingTitleCardView(
                systemImage: "trophy.circle.fill",
                title: "Health Goal",
                message: "What is your health goal?"
            )
        } bottom: {
            List {
                Section {
                    OnboardingHealthGoalCell(
                        title: "Lose Weight",
                        systemImage: "gauge.with.dots.needle.bottom.0percent",
                        isSelected: healthManager.healthGoal == .loseWeight
                    )
                    .onTapGesture {
                        healthManager.healthGoal = .loseWeight
                    }

                    OnboardingHealthGoalCell(
                        title: "Maintain Weight",
                        systemImage: "gauge.with.dots.needle.bottom.50percent",
                        isSelected: healthManager.healthGoal == .maintainWeight
                    )
                    .onTapGesture {
                        healthManager.healthGoal = .maintainWeight
                    }

                    OnboardingHealthGoalCell(
                        title: "Gain Weight",
                        systemImage: "gauge.with.dots.needle.bottom.100percent",
                        isSelected: healthManager.healthGoal == .gainWeight
                    )
                    .onTapGesture {
                        healthManager.healthGoal = .gainWeight
                    }
                }

                if healthManager.healthGoal == .loseWeight {
                    Section {
                        LabeledContent("Weight Difference") {
                            HStack {
                                TextField(
                                    "",
                                    value: $healthManager.targetWeightDifference,
                                    formatter: NumberFormatter.oneDecimalPlace
                                )
                                .selectAllTextOnBeginEditing()
                                .multilineTextAlignment(.trailing)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                                .font(.title3)
                                .fontDesign(.rounded)
                                .bold()
                                Text("lbs")
                            }
                        }

                        Picker("", selection: $healthManager.weightLossSpeed) {
                            ForEach(HealthManager.WeightLossSpeed.allCases) { speed in
                                Text(speed.name)
                                    .tag(speed)
                            }
                        }
                        .pickerStyle(.segmented)
                    } header: {
                        Text("How Much?")
                    } footer: {
                        Text(healthManager.weightLossSpeed.weightLossDescription)
                    }
                }
            }
        }
        .shelf(spacing: 0) {
            VStack {
                if healthManager.healthGoal == .loseWeight && healthManager.targetWeightDifference < 1 {
                    Text("Please enter how much weight you want to lose.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ProminentButton("Continue") {
                    onContinue()
                }
                .disabled(!canContinue)
            }
        }
        .animation(.default, value: healthManager.healthGoal)
    }
}

private extension OnboardingHealthGoalView {

    var canContinue: Bool {
        if healthManager.healthGoal == .none {
            return false
        }

        if healthManager.healthGoal == .loseWeight {
            if healthManager.targetWeightDifference < 1 {
                return false
            }
        }

        return true
    }
}

struct OnboardingHealthGoalCell: View {
    let title: String
    let systemImage: String
    let isSelected: Bool

    var body: some View {
        HStack {
            Image(systemName: systemImage)
                .foregroundStyle(.text, .tint)
                .font(.title3)
                .bold()

            Text(title)
                .bold()

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white, .tint)
                    .font(.title3)
                    .contentTransition(.symbolEffect)
            }
        }
        .selectable()
    }
}

#Preview {
    OnboardingHealthGoalView { }
}
