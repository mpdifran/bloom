//
//  NutritionQuickActionCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-27.
//

import SwiftUI

struct NutritionQuickActionCell: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        VStack {
            HStack {
                Image(systemName: systemImage)
                    .foregroundStyle(.tint)

                VStack(alignment: .leading) {
                    Text(title)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
            }
            .font(.body)
            .fontDesign(.rounded)
            .bold()
        }
        .cardContainer(fill: .tint.quinary, stroke: .tint.quaternary)
        .tint(.mutedGreen)
        .selectable()
    }
}

#Preview {
    HStack {
        NutritionQuickActionCell(
            title: "AI Scan",
            subtitle: "Log food instantly via AI.",
            systemImage: "sparkles"
        )
        NutritionQuickActionCell(
            title: "Scan Barcode",
            subtitle: "Scan a barcode to quickly log food.",
            systemImage: "barcode.viewfinder"
        )
    }
    .padding()
}
