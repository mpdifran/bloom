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
  let numberOfServings: Double

  init(
    protein: Double?,
    carbohydrates: Double?,
    fat: Double?,
    numberOfServings: Double
  ) {
    self.protein = protein ?? 0
    self.carbohydrates = carbohydrates ?? 0
    self.fat = fat ?? 0
    self.numberOfServings = numberOfServings
  }

  var body: some View {
    VStack {
      HStack {
        VStack {
          Text("\(proteinValue.format()) g")
            .contentTransition(.numericText(value: proteinValue))
          Text("Protein")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        VStack {
          Text("\(carbsValue.format()) g")
            .contentTransition(.numericText(value: carbsValue))
          Text("Carbs")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        VStack {
          Text("\(fatValue.format()) g")
            .contentTransition(.numericText(value: fatValue))
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

  var proteinValue: Double {
    protein * numberOfServings
  }

  var carbsValue: Double {
    carbohydrates * numberOfServings
  }

  var fatValue: Double {
    fat * numberOfServings
  }

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
    fat: 2,
    numberOfServings: 1
  )
  FoodItemMacroDistribution(
    protein: 1,
    carbohydrates: 2,
    fat: 3,
    numberOfServings: 2
  )
  FoodItemMacroDistribution(
    protein: 0,
    carbohydrates: 0,
    fat: 0,
    numberOfServings: 2
  )
}
