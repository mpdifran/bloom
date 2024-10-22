//
//  NutritionRemainingValueView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-16.
//

import SwiftUI

struct NutritionRemainingValueView: View {
    let systemImage: String
    let value: Double
    let valueText: String
    let title: String

    var body: some View {
        VStack {
            Gauge(value: value) {

            } currentValueLabel: {
                Image(systemName: systemImage)
                    .font(.body)
            }
            .gaugeStyle(.accessoryCircularCapacity)

            Text(valueText)
                .bold()

            Group {
                Text(title)
                Text("Remaining")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    HStack(spacing: 10) {
        NutritionRemainingValueView(
            systemImage: "carrot",
            value: 0.4,
            valueText: "1500 Cal",
            title: "Dietary Calories"
        )
        .tint(.mutedOrange)

        NutritionRemainingValueView(
            systemImage: "fork.knife",
            value: 0.6,
            valueText: "34 g",
            title: "Protein"
        )
        .tint(.protein)
    }
    .horizontallyCentered()
    .cardContainer()
    .padding()
    .groupedBackground()
}
