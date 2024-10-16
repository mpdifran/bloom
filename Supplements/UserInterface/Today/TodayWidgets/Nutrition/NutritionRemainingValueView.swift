//
//  NutritionRemainingValueView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-10-16.
//

import SwiftUI

struct NutritionRemainingValueView: View {
    let value: String
    let subtitle: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title)
                .bold()
                .fontDesign(.rounded)
                .foregroundStyle(.tint)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HStack(spacing: 10) {
        NutritionRemainingValueView(
            value: "1500 Cal",
            subtitle: "Dietary Calories"
        )
        
        NutritionRemainingValueView(
            value: "34 g",
            subtitle: "Protein"
        )
    }
    .horizontallyCentered()
    .cardContainer()
    .padding()
    .groupedBackground()
}
