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
                    if food.isVerified {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(.white, .mutedGreen)
                        Text("Verified")
                            .foregroundStyle(.mutedGreen)
                            .bold()
                    }

                    Text(food.brandName ?? "Unknown")
                        .foregroundStyle(.secondary)
                        .bold()
                }
                .font(.caption)

                HStack(alignment: .firstTextBaseline) {
                    Text(food.name)
                    if let flavour = food.flavour {
                        Text(flavour)
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    }
                }
                .bold()

                if
                    let serving = food.servingName,
                    let servingQuantity = food.servingQuantity
                {
                    Text("\(serving) (\(servingQuantity.value.format()) \(servingQuantity.unit))")
                        .font(.caption)
                }
            }

            Spacer()

            if let calories = food.calories {
                VStack(spacing: 0) {
                    Text("\(calories.format())")
                        .bold()
                        .font(.title2)
                        .foregroundStyle(.tint)
                    Text("cals")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .fontDesign(.rounded)
            }

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
                    name: "Yogurt",
                    brandName: "Activia",
                    flavour: "Rhubarb",
                    nutrients: [
                        .init(kind: .protein, quantity: .init(value: 3.9, unit: "g")),
                        .init(kind: .calories, quantity: .init(value: 91, unit: "kcal")),
                        .init(kind: .carbohydrates, quantity: .init(value: 12, unit: "g")),
                        .init(kind: .fat, quantity: .init(value: 2.8, unit: "g")),
                    ],
                    servingName: "1 package",
                    servingQuantity: .init(value: 43, unit: "g"),
                    ingredients: "Yogurt (Milk);  Rhubarb (8%);  Sugar;  Tapioca Starch;  Natural Flavourings;  Colour (Plain Caramel);  Stabiliser (Pectin);  Milk Minerals;  Cultures (Lactobacillus Bulgaricus;  Streptococcus Thermophilus;  Lactococcus Lactis;  Bifidobacterium Lactis (Bifidus Actiregularis®))",
                    isVerified: false
                )
            )
            FoodItemCell(
                food: .init(
                    id: .init(),
                    name: "Crackers",
                    brandName: "Ritz",
                    flavour: "Low Sodium",
                    nutrients: [
                        .init(kind: .protein, quantity: .init(value: 3.9, unit: "g")),
                        .init(kind: .calories, quantity: .init(value: 91, unit: "kcal")),
                        .init(kind: .carbohydrates, quantity: .init(value: 12, unit: "g")),
                        .init(kind: .fat, quantity: .init(value: 2.8, unit: "g")),
                    ],
                    servingName: "1 package",
                    servingQuantity: .init(value: 43, unit: "g"),
                    ingredients: "Yogurt (Milk);  Rhubarb (8%);  Sugar;  Tapioca Starch;  Natural Flavourings;  Colour (Plain Caramel);  Stabiliser (Pectin);  Milk Minerals;  Cultures (Lactobacillus Bulgaricus;  Streptococcus Thermophilus;  Lactococcus Lactis;  Bifidobacterium Lactis (Bifidus Actiregularis®))",
                    isVerified: true
                )
            )
        }
        .padding()
    }
}
