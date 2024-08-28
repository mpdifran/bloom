//
//  OnboardingGoalDetails.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-08-28.
//

import SwiftUI

struct OnboardingGoalDetails: View {
    let goal: GoalModel

    @ObservedObject private var vitalsViewModel = VitalsViewModel.shared

    var body: some View {
        VStack {
            HStack {
                Image(systemName: goal.systemImage)
                    .foregroundStyle(goal.metric.measurement.color)
                    .font(.largeTitle)

                VStack(alignment: .leading) {
                    Text(goal.title)
                        .font(.title3)
                        .bold()
                    Text("Due \(DateFormatter.relativeTimeIntervalDaysFullFromNow(goal.dueDate))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.leading)

                Spacer()

                Text("\(goal.metric.value.format()) \(goal.metric.unitString)")
                    .font(.title2)
                    .bold()
                    .fontDesign(.rounded)
                    .foregroundStyle(goal.metric.measurement.color)
            }


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
