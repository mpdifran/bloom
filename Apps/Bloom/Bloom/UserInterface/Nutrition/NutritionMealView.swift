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

  @Binding private var isSwipingItem: Bool

  let meal: FoodItemLog.Meal
  let foodItemLogs: [FoodItemLog]
  let onCellTapped: (FoodItemLog) -> Void
  let onLogTapped: () -> Void

  init(
    meal: FoodItemLog.Meal,
    foodItemLogs: [FoodItemLog],
    isSwipingItem: Binding<Bool>,
    onCellTapped: @escaping (FoodItemLog) -> Void,
    onLogTapped: @escaping () -> Void
  ) {
    self.meal = meal
    self.foodItemLogs = foodItemLogs
    self._isSwipingItem = isSwipingItem
    self.onCellTapped = onCellTapped
    self.onLogTapped = onLogTapped
  }

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  @State private var error: Error?

  var body: some View {
    VStack(spacing: 16) {
      mealHeader

      VStack {
        if foodItemLogs.isEmpty {
          noContentView
        } else {
          contentView
        }
      }
    }
    .padding(.vertical)
    .alert(error: $error)
  }
}

private extension NutritionMealView {

  func delete(_ foodItemLog: FoodItemLog) {
    Task {
      do {
        try await nutritionViewModel.delete(foodItemLogs: [foodItemLog])
      } catch {
        self.error = error
      }
    }
  }
}

private extension NutritionMealView {

  var noContentView: some View {
    Text("No Food Logged")
      .font(.title2)
      .foregroundStyle(.secondary)
      .bold()
      .padding()
      .horizontallyCentered()
      .cardContainer()
  }

  var contentView: some View {
    ForEach(foodItemLogs) { foodItemLog in
      Swipeable(
        isSwipingItem: $isSwipingItem,
        actions: [
          .init(
            title: "Delete",
            systemImage: "trash",
            tint: .mutedRed,
            action: {
              delete(foodItemLog)
            }
          )
        ]
      ) {
        FoodItemLogCell(foodItemLog: foodItemLog)
          .id(foodItemLog.id)
      }
      .onTapGesture {
        onCellTapped(foodItemLog)
      }
    }
  }

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
  @Previewable @State var isSwipingItem = false
  VStack {
    NutritionMealView(
      meal: .lunch,
      foodItemLogs: [],
      isSwipingItem: $isSwipingItem
    ) { _ in

    } onLogTapped: {

    }
    .padding()
  }
  .groupedBackground()
}
