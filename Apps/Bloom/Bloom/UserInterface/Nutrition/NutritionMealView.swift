//
//  NutritionMealView.swift
//  Supplements
//
//  Created by Zach Radford on 2025-01-18.
//

import SFSafeSymbols
import AppUI
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
      mealHeader

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
          Button("Duplicate", systemSymbol: .docOnDoc) {
            presentedSheet = DuplicateFoodLogView(
              foodItemLog: foodItemLog,
              performDismiss: nil
            ).asAny
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

  var mealHeader: some View {
    HStack {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 12) {
          Text(meal.name)
            .font(
              .system(
                .headline,
                design: .rounded,
                weight: .black
              )
            )
          
          if !foodItemLogs.isEmpty {
            MacroDistributionBar(
              proteinGrams: foodItemLogs.totalProtein,
              carbsGrams: foodItemLogs.totalCarbs,
              fatGrams: foodItemLogs.totalFat
            )
            .frame(width: 60)
          }
        }

        Text("\(foodItemLogs.totalCalories.format()) Cals • \(foodItemLogs.totalProtein.format()) g Protein •  \(foodItemLogs.totalCarbs.format()) g Carbs • \(foodItemLogs.totalFat.format()) g Fats")
          .font(.caption)
          .foregroundStyle(.secondary)
          .bold()
      }

      Spacer()

      Button {
        onLogTapped()
      } label: {
        Label("Add", systemSymbol: .plus)
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
