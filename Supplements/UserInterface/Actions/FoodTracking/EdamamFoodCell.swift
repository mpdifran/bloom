//
//  EdamamFoodCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-07.
//

import SwiftUI

struct EdamamFoodCell: View {
    let food: Supplements.Components.Schemas.Food

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    if food.brand != nil {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.white, .mutedGreen)
                    }
                    Text(food.brand ?? "Unknown")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)

                Text(food.label ?? "Unknown")
                    .bold()

                if let serving = food.servingSizes?.first {
                    Text("\(serving.quantity?.format() ?? "0") \(serving.label ?? "unknown")")
                        .font(.subheadline)
                }
            }

            Spacer()

            Button {

            } label: {
                Image(systemName: "plus.circle.fill")
                    .foregroundStyle(.white, .tint)
                    .font(.largeTitle)
            }
        }
        .cardContainer(fill: .background.secondary)
    }
}

#Preview {
    ScrollView {
        VStack {
            EdamamFoodCell(
                food: .init(
                    label: "Vector Cereal",
                    brand: "Kellogg's",
                    servingSizes: [
                        .init(label: "grams", quantity: 100)
                    ]
                )
            )
        }
        .padding()
    }
}
