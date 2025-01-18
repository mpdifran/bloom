//
//  NutritionMealView.swift
//  Supplements
//
//  Created by Zach Radford on 2025-01-18.
//

import DataContainer
import SwiftUI

struct NutritionMealView: View {

  let meal: FoodItemLog.Meal
  let foodItemLogs: [FoodItemLog]
  let onCellTapped: (FoodItemLog) -> Void
  let onLogTapped: () -> Void

  var body: some View {
    mealHeader

    VStack(spacing: 0) {
      if foodItemLogs.isEmpty {
        Text("No Food Logged")
          .font(.title2)
          .foregroundStyle(.secondary)
          .bold()
          .padding()
          .padding()
      } else {
        ForEach(foodItemLogs) { foodItemLog in
          FoodItemLogCell(foodItemLog: foodItemLog)
            .id(foodItemLog.id)
            .transition(.blurReplace)
            .selectable()
            .onTapGesture {
              onCellTapped(foodItemLog)
            }
            .padding()
          Divider()
            .padding(.horizontal)
        }
      }
    }
    .horizontallyCentered()
    .cardContainer(includePadding: false)
  }
}

private extension NutritionMealView {
  var mealHeader: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(meal.name)
          .font(.title2)
          .fontDesign(.rounded)
          .bold()

        Text("\(totalCalories.format()) cal • \(totalProtein.format()) Protein • \(totalFat.format()) Fats • \(totalCarbs.format()) Carbs")
          .font(.caption)
          .foregroundStyle(.secondary)
          .bold()
      }

      Spacer()

      Button {
        onLogTapped()
      } label: {
        Label("Add", systemImage: "plus")
          .padding(8)
          .background(Color.white)
          .foregroundStyle(.tint)
          .clipShape(Capsule())
          .bold()
      }
    }
  }
}

private extension NutritionMealView {
  var totalCalories: Double {
    foodItemLogs.reduce(0) { partialResult, foodItemLog in
      partialResult + foodItemLog.totalCalories
    }
  }

  var totalProtein: Double {
    foodItemLogs.reduce(0) { partialResult, foodItemLog in
      partialResult + foodItemLog.totalProtein
    }
  }

  var totalFat: Double {
    foodItemLogs.reduce(0) { partialResult, foodItemLog in
      partialResult + foodItemLog.totalFat
    }
  }

  var totalCarbs: Double {
    foodItemLogs.reduce(0) { partialResult, foodItemLog in
      partialResult + foodItemLog.totalCarbs
    }
  }
}
