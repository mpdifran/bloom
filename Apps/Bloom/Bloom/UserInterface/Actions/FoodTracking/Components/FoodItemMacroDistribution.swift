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
  static let smallBarHeight: CGFloat = 8
}

extension FoodItemMacroDistribution {
  enum DisplayType {
    case small
    case regular
  }
}

struct FoodItemMacroDistribution: View {
  let displayType: DisplayType
  let protein: Double
  let carbohydrates: Double
  let fat: Double
  let numberOfServings: Double

  init(
    displayType: DisplayType = .regular,
    protein: Double?,
    carbohydrates: Double?,
    fat: Double?,
    numberOfServings: Double
  ) {
    self.displayType = displayType
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
            .font(displayType == .small ? .caption : .body)
            .contentTransition(.numericText(value: proteinValue))
          Text("Protein")
            .font(displayType == .small ? .caption2 : .caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        VStack {
          Text("\(carbsValue.format()) g")
            .font(displayType == .small ? .caption : .body)
            .contentTransition(.numericText(value: carbsValue))
          Text("Carbs")
            .font(displayType == .small ? .caption2 : .caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        VStack {
          Text("\(fatValue.format()) g")
            .font(displayType == .small ? .caption : .body)
            .contentTransition(.numericText(value: fatValue))
          Text("Fat")
            .font(displayType == .small ? .caption2 : .caption)
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
      .frame(height: displayType == .small ? .smallBarHeight : .barHeight)
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
    total > 0 ? CGFloat((protein * .caloriesPerGramOfProtein) / total) : 1/3
  }

  var carbohydratesPercent: CGFloat {
    total > 0 ? CGFloat((carbohydrates * .caloriesPerGramOfCarbs) / total) : 1/3
  }

  var fatPercent: CGFloat {
    total > 0 ? CGFloat((fat * .caloriesPerGramOfFat) / total) : 1/3
  }

  var total: Double {
    protein * .caloriesPerGramOfProtein +
    carbohydrates * .caloriesPerGramOfCarbs +
    fat * .caloriesPerGramOfFat
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      FoodItemMacroDistribution(
        protein: 12,
        carbohydrates: 40,
        fat: 2,
        numberOfServings: 1
      )
      FoodItemMacroDistribution(
        displayType: .small,
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
    .padding()
  }
}
