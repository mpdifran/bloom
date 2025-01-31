//
//  NutrientsRemainingView.swift
//  Bloom
//
//  Created by Zach Radford on 2025-01-30.
//

import AppUI
import SwiftUI
import DataContainer

struct NutrientsRemainingView: View {

  private let foodItemLogs: [FoodItemLog]

  init(foodItemLogs: [FoodItemLog]) {
    self.foodItemLogs = foodItemLogs
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      titleView

      cardView
    }
  }
}

private extension NutrientsRemainingView {
  var titleView: some View {
    Text("Nutrients remaining")
      .font(
        .system(
          .headline,
          design: .rounded,
          weight: .black
        )
      )
  }

  var cardView: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(totalCalories.format())
          .font(
            .system(
              .title3,
              design: .rounded,
              weight: .black
            )
          )

        Text("Calories")
          .bold()
          .foregroundStyle(.secondary)
          .font(.caption)
      }

      Spacer()
    }
    .cardContainer()
  }

  var totalCalories: Double {
    foodItemLogs.reduce(0) { partialResult, foodItemLog in
      partialResult + foodItemLog.totalCalories
    }
  }
}
