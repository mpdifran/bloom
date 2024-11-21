//
//  FoodItemMacroDistribution.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-21.
//

import SwiftUI
import BloomModel

private extension CGFloat {
    static let barHeight: CGFloat = 12
}

struct FoodItemMacroDistribution: View {
    let protein: Double
    let carbohydrates: Double
    let fat: Double

    init(protein: Double?, carbohydrates: Double?, fat: Double?) {
        self.protein = protein ?? 0
        self.carbohydrates = carbohydrates ?? 0
        self.fat = fat ?? 0
    }

    var body: some View {
        VStack {
            HStack {
                VStack {
                    Text("\(protein.format()) g")
                    Text("Protein")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack {
                    Text("\(carbohydrates.format()) g")
                    Text("Carbs")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack {
                    Text("\(fat.format()) g")
                    Text("Fat")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .bold()
            .padding(.horizontal)

            GeometryReader { proxy in
                HStack(spacing: 0) {
                    Rectangle()
                        .fill(.protein)
                        .frame(width: proxy.size.width * proteinPercent)

                    Rectangle()
                        .fill(.carbohydrates)
                        .frame(width: proxy.size.width * carbohydratesPercent)

                    Rectangle()
                        .fill(.fat)
                        .frame(width: proxy.size.width * fatPercent)
                }
            }
            .frame(height: .barHeight)
            .clipShape(Capsule())
        }
    }
}

private extension FoodItemMacroDistribution {

    var proteinPercent: CGFloat {
        CGFloat((protein * .caloriesPerGramOfProtein) / total)
    }

    var carbohydratesPercent: CGFloat {
        CGFloat((carbohydrates * .caloriesPerGramOfCarbs) / total)
    }

    var fatPercent: CGFloat {
        CGFloat((fat * .caloriesPerGramOfFat) / total)
    }

    var total: Double {
        protein * .caloriesPerGramOfProtein +
        carbohydrates * .caloriesPerGramOfCarbs +
        fat * .caloriesPerGramOfFat
    }
}

#Preview {
    FoodItemMacroDistribution(
        protein: 12,
        carbohydrates: 40,
        fat: 2
    )
}
