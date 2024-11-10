//
//  FoodItemCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-07.
//

import SwiftUI
import BloomModel

struct FoodItemCell: View {
    let food: FoodItem

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(spacing: 4) {
                    if food.brandName != nil {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.white, .mutedGreen)
                    }
                    Text(food.brandName ?? "Unknown")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)

                Text(food.name)
                    .bold()

                if let serving = food.servingSizes.first {
                    Text("\(serving.value.format()) \(serving.unit)")
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
            FoodItemCell(
                food: .init(
                    id: .init(),
                    name: "Activia Rhubarb Yogurt",
                    brandName: "Activia",
                    nutrients: [
                        .init(kind: .protein, quantity: .init(value: 3.9, unit: "g")),
                        .init(kind: .calories, quantity: .init(value: 91, unit: "kcal")),
                        .init(kind: .carbohydrates, quantity: .init(value: 12, unit: "g")),
                        .init(kind: .fat, quantity: .init(value: 2.8, unit: "g")),
                    ],
                    servingSizes: [
                        .init(value: 100, unit: "g")
                    ],
                    ingredients: "Yogurt (Milk);  Rhubarb (8%);  Sugar;  Tapioca Starch;  Natural Flavourings;  Colour (Plain Caramel);  Stabiliser (Pectin);  Milk Minerals;  Cultures (Lactobacillus Bulgaricus;  Streptococcus Thermophilus;  Lactococcus Lactis;  Bifidobacterium Lactis (Bifidus Actiregularis®))"
                )
            )
        }
        .padding()
    }
}
