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
    let color: Color

    var body: some View {
        VStack {
            IconGauge(
                progress: value,
                dimension: 70,
                lineThickness: 12,
                systemImage: systemImage,
                color: color
            )

            Text(valueText)
                .font(.title3)
                .bold()
                .fontDesign(.rounded)

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
            title: "Dietary Calories",
            color: .mutedOrange
        )

        NutritionRemainingValueView(
            systemImage: "fork.knife",
            value: 0.6,
            valueText: "34 g",
            title: "Protein",
            color: .protein
        )
    }
    .horizontallyCentered()
    .cardContainer()
    .padding()
    .groupedBackground()
}
