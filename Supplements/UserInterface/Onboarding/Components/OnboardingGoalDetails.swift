//
//  OnboardingGoalDetails.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI
import DataContainer

struct OnboardingGoalDetails: View {
    let goal: GoalModel

    @ObservedObject private var vitalsViewModel = VitalsViewModel.shared

    var body: some View {
        VStack {
            HStack {
                Image(systemName: goal.systemImage)
                    .foregroundStyle(.tint)
                    .font(.largeTitle)

                VStack(alignment: .leading) {
                    Text(goal.title)
                        .font(.title3)
                        .bold()
                }
                .multilineTextAlignment(.leading)

                Spacer()

                GoalDailyTargetTagView(formattedTarget: goal.metric.targetDailyQuantity.displayString(for: goal.metric.unit))
            }
            .tint(goal.metric.measurement.color)


            if let targetVitalModel {
                TargetVitalComponentView(vital: targetVitalModel)
            }
        }
        .cardContainer(fill: .background.secondary)
    }
}

private extension OnboardingGoalDetails {

    var targetVitalModel: VitalModel? {
        vitalsViewModel.vitals.first(where: { $0.id == goal.vitalKind })
    }
}

#Preview {
    OnboardingGoalDetails(
        goal: .init(
            title: "Run Longer Distances",
            systemImage: "figure.run",
            summary: "You need to run longer",
            dueDate: Date().addingTimeInterval(363600),
            metric: .init(
                value: 2,
                unit: .meterUnit(with: .kilo),
                measurement: .runDistance
            ),
            vitalKind: .cardioFitness
        )
    )
    .padding()
}
