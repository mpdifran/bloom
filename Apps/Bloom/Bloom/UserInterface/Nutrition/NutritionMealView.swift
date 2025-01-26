//
//  NutritionMealView.swift
//  Supplements
//
//  Created by Zach Radford on 2025-01-18.
//

import AppUI
import DataContainer
import SwiftUI

struct NutritionMealView: View {

  let meal: FoodItemLog.Meal
  let foodItemLogs: [FoodItemLog]
  let onCellTapped: (FoodItemLog) -> Void
  let onLogTapped: () -> Void

  @State private var isSwipingItem = false

  var body: some View {
    VStack(spacing: 16) {
      mealHeader

      VStack {
        if foodItemLogs.isEmpty {
          Text("No Food Logged")
            .font(.title2)
            .foregroundStyle(.secondary)
            .bold()
            .padding()
            .horizontallyCentered()
            .cardContainer()
        } else {
          ForEach(foodItemLogs) { foodItemLog in
            Swipeable(
              isSwipingItem: $isSwipingItem,
              actions: [
                .init(
                  title: "Delete",
                  systemImage: "trash",
                  tint: .mutedRed,
                  action: {

                  }
                )
              ]
            ) {
              FoodItemLogCell(foodItemLog: foodItemLog)
                .id(foodItemLog.id)
                .transition(.blurReplace)
                .selectable()
                .onTapGesture {
                  onCellTapped(foodItemLog)
                }
            }
          }
        }
      }
    }
    .padding(.vertical)
  }
}

private extension NutritionMealView {
  var mealHeader: some View {
    HStack {
      VStack(alignment: .leading, spacing: 6) {
        Text(meal.name)
          .font(
            .system(
              .headline,
              design: .rounded,
              weight: .black
            )
          )

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
          .padding(.vertical, 8)
          .padding(.horizontal, 12)
          .foregroundStyle(.tint)
          .font(.subheadline)
          .fontDesign(.rounded)
          .bold()
          .background(.background)
          .clipShape(Capsule())
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

#Preview {
  VStack {
    NutritionMealView(
      meal: .lunch,
      foodItemLogs: []
    ) { _ in

    } onLogTapped: {

    }
    .padding()
  }
  .groupedBackground()
}
