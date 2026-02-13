//
//  NutritionMealView.swift
//  Supplements
//
//  Created by Zach Radford on 2025-01-18.
//

import SFSafeSymbols
import AppUI
import BloomModel
import DataContainer
import SwiftUI
import CoreHealth

struct NutritionMealView: View {

  private let meal: FoodItemLog.Meal
  private let foodItemLogs: [FoodItemLog]
  private let onCellTapped: (FoodItemLog, FoodItemRecord) -> Void
  private let showMealDetails: (FoodItemLog) -> Void
  private let onLogTapped: () -> Void
  @Binding private var presentedSheet: AnyView?

  init(
    meal: FoodItemLog.Meal,
    foodItemLogs: [FoodItemLog],
    presentedSheet: Binding<AnyView?>,
    onCellTapped: @escaping (FoodItemLog, FoodItemRecord) -> Void,
    showMealDetails: @escaping (FoodItemLog) -> Void,
    onLogTapped: @escaping () -> Void
  ) {
    self.meal = meal
    self.foodItemLogs = foodItemLogs
    self._presentedSheet = presentedSheet
    self.onCellTapped = onCellTapped
    self.showMealDetails = showMealDetails
    self.onLogTapped = onLogTapped
  }

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  @Environment(\.modelContext) private var modelContext

  @State private var error: Error?

  var body: some View {
    VStack(spacing: 16) {
      MealHeaderView(
        mealName: meal.name,
        totalCalories: foodItemLogs.totalCalories,
        totalProtein: foodItemLogs.totalProtein,
        totalCarbs: foodItemLogs.totalCarbs,
        totalFat: foodItemLogs.totalFat,
        onLogTapped: onLogTapped,
        onSaveAsMeal: foodItemLogs.isEmpty ? nil : { saveAsMeal() }
      )

      VStack(spacing: 8) {
        if foodItemLogs.isEmpty {
          noContentView
        } else {
          contentView
        }
      }
    }
    .alert(error: $error)
  }
}

private extension NutritionMealView {

  func delete(_ foodItemLog: FoodItemLog) async {
    do {
      try await nutritionViewModel.delete(modelContext: modelContext, foodItemLogs: [foodItemLog])
    } catch {
      self.error = error
    }
  }

  func retry(_ foodItemLog: FoodItemLog) async throws {
    try await nutritionViewModel.retryMagicScan(
      modelContext: modelContext,
      foodItemLog: foodItemLog
    )
  }

  func changeMeal(_ foodItemLog: FoodItemLog, to newMeal: FoodItemLog.Meal) async {
    do {
      try await nutritionViewModel.changeMeal(
        modelContext: modelContext,
        foodItemLog: foodItemLog,
        to: newMeal
      )
    } catch {
      self.error = error
    }
  }

  func saveAsMeal() {
    var foodItems = [FoodItem]()
    var servings = [FoodItemIdentifier: Double]()

    for log in foodItemLogs {
      for serving in log.foodItemServings ?? [] {
        guard let foodItemRecord = serving.foodItem else { continue }
        let foodItem = foodItemRecord.asNetworkFoodItem()
        foodItems.append(foodItem)
        servings[foodItem.id] = serving.numberOfServings
      }
    }

    presentedSheet = CreateEditMealView(
      prefillFoodItems: foodItems,
      prefillServings: servings
    ).asAny
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
      // Check if this is a Magic Scanner item with processing/error state
      if let processingState = foodItemLog.processingState,
         processingState != .completed {
        MagicScannerProcessingCell(foodItemLog: foodItemLog) {
          try await retry(foodItemLog)
        } onDelete: {
          await delete(foodItemLog)
        }
        .id(foodItemLog.id)
        .contextMenu {
          // Only show delete for processing items
          Button("Delete", systemSymbol: .trash, role: .destructive) {
            Task {
              await delete(foodItemLog)
            }
          }
          .tint(.red)
        }
      } else {
        // Normal food item log cell
        FoodItemLogCell(foodItemLog: foodItemLog) { foodItem in
          onCellTapped(foodItemLog, foodItem)
        } showMealDetails: { foodItemLog in
          showMealDetails(foodItemLog)
        }
        .id(foodItemLog.id)
        .contextMenu {
          Button("Copy Log", systemSymbol: .documentOnDocument) {
            presentedSheet = DuplicateFoodLogView(
              foodItemLog: foodItemLog,
              performDismiss: nil
            ).asAny
          }

          Menu {
            ForEach(FoodItemLog.Meal.allCases.filter { $0 != meal }, id: \.self) { mealOption in
              Button(mealOption.name) {
                Task {
                  await changeMeal(foodItemLog, to: mealOption)
                }
              }
            }
          } label: {
            Label("Change Meal", systemSymbol: .arrowUpArrowDown)
          }

          Divider()

          Button("Delete", systemSymbol: .trash, role: .destructive) {
            Task {
              await delete(foodItemLog)
            }
          }
          .tint(.red)
        }
      }
    }
  }
}

#Preview {
  PreviewEnvironment {
    VStack {
      NutritionMealView(
        meal: .lunch,
        foodItemLogs: [],
        presentedSheet: .constant(nil)
      ) { (_, _) in
        
      } showMealDetails: { (_) in
        
      } onLogTapped: {
        
      }
      .padding()
    }
    .groupedBackground()
  }
}
