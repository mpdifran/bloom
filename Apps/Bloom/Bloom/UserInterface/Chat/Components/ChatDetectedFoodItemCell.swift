//
//  ChatDetectedFoodItemCell.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-04-17.
//

import SwiftUI
import BloomModel
import CoreHealth

struct ChatDetectedFoodItemCell: View {
  let foodItemServing: FoodItemServingAmount

  var body: some View {
    HStack {
      foodDetailsContentView

      Spacer()

      caloriesView
    }
  }
}

private extension ChatDetectedFoodItemCell {

  var food: FoodItem {
    foodItemServing.foodItem
  }

  var foodDetailsContentView: some View {
    VStack(alignment: .leading) {
      Text(food.name)
        .bold()

      Group {
        if let serving = food.servingName, let servingQuantity = food.servingQuantity {
          Text(verbatim: "\(serving) (\(servingQuantity.value.format()) \(servingQuantity.unit))")
        }
        Text("\(NumberFormatter.noDecimalPlaces.string(for: foodItemServing.serving) ?? "") servings")
      }
      .foregroundStyle(.secondary)
      .font(.caption)
    }
    .selectable()
  }

  @ViewBuilder
  var caloriesView: some View {
    if let calories = food.calories?.value {
      VStack(spacing: 0) {
        Text(verbatim: "\(calories.format())")
          .bold()
          .font(.title2)
          .foregroundStyle(.tint)
        Text("cal")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .fontDesign(.rounded)
    }
  }
}

#Preview {
  ChatDetectedFoodItemCell(
    foodItemServing: FoodItemServingAmount(
      serving: 2,
      foodItem: .Preview.ritzCrackers
    )
  )
}
