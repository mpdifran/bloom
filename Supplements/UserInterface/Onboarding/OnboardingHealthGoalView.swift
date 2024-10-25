//
//  OnboardingHealthGoalView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-09-13.
//

import SwiftUI
import AppUI
import HealthKit

struct OnboardingHealthGoalView: View {
    let onContinue: () -> Void

    @ObservedObject private var healthManager = HealthManager.shared

    @State private var index = 1
    @State private var didContinue = false

    @State private var presentedSheet: AnyView?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    Text("Let's talk about your goals.")
                        .transition(.opacity)
                        .appear(with: 1, currentIndex: index)

                    Text("Where would you like to focus your efforts?")
                        .transition(.opacity)
                        .appear(with: 2, currentIndex: index)
                }
                .font(.title)
                .bold()
                .fontDesign(.rounded)

                goalPickerView
                    .transition(.blurReplace)
                    .appear(with: 3, currentIndex: index)

                if healthManager.healthGoal == .loseWeight || healthManager.healthGoal == .gainWeight {
                    targetWeightView
                        .transition(.blurReplace)
                        .appear(with: 3, currentIndex: index)
                }
            }
            .horizontalAlignment(.leading)
            .padding()
        }
        .topSafeAreaBlur()
        .sheet($presentedSheet)
        .animation(.default, value: index)
        .animation(.default, value: healthManager.healthGoal)
        .sensoryFeedback(.selection, trigger: index)
        .sensoryFeedback(.selection, trigger: didContinue)
        .shelf(spacing: 0) {
            if index >= 3 {
                VStack {
                    if healthManager.healthGoal == .loseWeight && healthManager.targetWeight < 1 {
                        Text("Please enter what your ideal weight is.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button("Looks Good") {
                        didContinue.toggle()
                        onContinue()
                    }
                    .buttonStyle(.onboarding)
                    .disabled(!canContinue)
                }
            }
        }
        .task {
            while index < 3 {
                await advanceIndex()
            }
        }
    }
}

private extension OnboardingHealthGoalView {

    var goalPickerView: some View {
        VStack {
            OnboardingHealthGoalCell(
                title: "Just Monitor My Health",
                systemImage: "heart.text.clipboard",
                isSelected: healthManager.healthGoal == .none
            )
            .onTapGesture {
                healthManager.healthGoal = .none
            }

            Divider()

            OnboardingHealthGoalCell(
                title: "Lose Weight",
                systemImage: "gauge.with.dots.needle.bottom.0percent",
                isSelected: healthManager.healthGoal == .loseWeight
            )
            .onTapGesture {
                healthManager.healthGoal = .loseWeight
            }

            Divider()

            OnboardingHealthGoalCell(
                title: "Maintain Weight",
                systemImage: "gauge.with.dots.needle.bottom.50percent",
                isSelected: healthManager.healthGoal == .maintainWeight
            )
            .onTapGesture {
                healthManager.healthGoal = .maintainWeight
            }

            Divider()

            OnboardingHealthGoalCell(
                title: "Gain Weight",
                systemImage: "gauge.with.dots.needle.bottom.100percent",
                isSelected: healthManager.healthGoal == .gainWeight
            )
            .onTapGesture {
                healthManager.healthGoal = .gainWeight
            }
        }
        .cardContainer(fill: .background.secondary)
    }


    var targetWeightView: some View {
        VStack(alignment: .leading) {
            VStack(spacing: 16) {
                LabeledContent("Target Weight") {
                    HStack {
                        Text("\(targetWeight.displayString(for: .pound()))")
                        Image(systemName: "chevron.up.chevron.down")
                    }
                    .font(.title3)
                    .fontDesign(.rounded)
                    .foregroundStyle(.tint)
                }
                .bold()
                .selectable()
                .onTapGesture {
                    presentedSheet = TargetWeightEditCard().asAny
                }

                if healthManager.healthGoal == .loseWeight || healthManager.healthGoal == .gainWeight {
                    Divider()
                    LabeledContent("Weight Loss Speed") {
                        Menu {
                            ForEach(WeightLossSpeed.allCases) { speed in
                                Button(speed.name, systemImage: speed == healthManager.weightLossSpeed ? "checkmark" : "") {
                                    healthManager.weightLossSpeed = speed
                                }
                            }
                        } label: {
                            HStack {
                                Text(healthManager.weightLossSpeed.name)
                                Image(systemName: "chevron.up.chevron.down")
                            }
                            .font(.title3)
                            .fontDesign(.rounded)
                            .bold()
                        }
                    }
                    .bold()
                }
            }
            .cardContainer(fill: .background.secondary)

            if healthManager.healthGoal == .loseWeight || healthManager.healthGoal == .gainWeight {
                Text(healthManager.weightLossSpeed.weightLossDescription)
                    .font(.subheadline)
                    .bold()
                    .fontDesign(.rounded)
                    .padding(.horizontal)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var targetWeight: HKQuantity {
        HKQuantity(unit: .pound(), doubleValue: healthManager.targetWeight)
    }

    func advanceIndex() async {
        await Delay(1700)

        index += 1
    }

    var canContinue: Bool {
        if healthManager.healthGoal == .loseWeight {
            if healthManager.targetWeight < 1 {
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
        .padding(.vertical, 8)
        .selectable()
    }
}

#Preview {
    OnboardingHealthGoalView { }
}
