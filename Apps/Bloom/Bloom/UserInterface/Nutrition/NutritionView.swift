//
//  NutritionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-04.
//

import SFSafeSymbols
import SwiftUI
import AppUI
import DataContainer
import SwiftData
import CoreHealth

struct NutritionView: View {

  @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

  @State private var presentedSheet: AnyView?

  @Environment(\.modelContext) private var modelContext

  @Environment(TabController.self) private var tabController: TabController

  var body: some View {
    NavigationStack {
      BloomScrollView(padding: .vertical) {
        topBar

        Group {
          NutrientsWidgetView()
            .transition(.blurReplace)
            .padding(.vertical)
            .onTapGesture {
              // TODO: where does this go?
            }

          FilteredFoodItemLogsListView(
            date: nutritionViewModel.date,
            presentedSheet: $presentedSheet
          )
          .transition(.blurReplace)
        }
        .padding(.horizontal)
      }
      .navigationTitle("Nutrition")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button {
            presentedSheet = FoodLoggingActionCardView().asAny
          } label: {
            Image(systemSymbol: .plus)
              .bold()
          }
          .buttonStyle(.plain)
        }

        SettingsProfileViewToolbarButton()
      }
    }
    .animation(.easeInOut, value: nutritionViewModel.date)
    .sheet($presentedSheet)
    .onChange(of: tabController.pendingFoodItemLogNavigation) { oldValue, newValue in
      if let logId = newValue {
        // Fetch the food item log
        if let foodItemLog = try? modelContext.fetchFoodItemLog(id: logId) {
          // Show different views based on whether it's a single item or multi-item meal
          if foodItemLog.hasSingleServing, let serving = foodItemLog.firstFoodItemServing, let foodItem = serving.foodItem {
            // Single food item - show food item details
            presentedSheet = FoodItemDetailsView(
              foodItem: foodItem.asNetworkFoodItem(),
              existingFoodItemLog: foodItemLog
            ).asAny
          } else {
            // Multi-item meal - show meal details
            presentedSheet = FoodItemLogDetailsView(foodItemLog: foodItemLog).asAny
          }
        }
        tabController.pendingFoodItemLogNavigation = nil
      }
    }
    .onChange(of: tabController.pendingFoodItemNavigation) { oldValue, newValue in
      if let foodItemId = newValue {
        // Fetch the food item from the database
        if let foodItemRecord = try? modelContext.fetchFirstFoodItem(for: foodItemId) {
          // Show food item details without an existing log
          presentedSheet = FoodItemDetailsView(
            foodItem: foodItemRecord.asNetworkFoodItem(),
            existingFoodItemLog: nil
          ).asAny
        }
        tabController.pendingFoodItemNavigation = nil
      }
    }
    .onChange(of: tabController.pendingSavedMealNavigation) { oldValue, newValue in
      if let mealId = newValue {
        // Fetch the saved meal and show details
        Task {
          let mealActor = MealRecordModelActor.standard()
          if let mealDTO = try? await mealActor.fetchMealRecord(for: mealId) {
            // For saved meals, we need to show the meal in a way the user can log it
            // Since there's no single food item, we'll need to show the food logging action
            // with the meal pre-selected, or create a temporary meal log view
            // For now, let's just open the food logging action card
            presentedSheet = FoodLoggingActionCardView().asAny
          }
          tabController.pendingSavedMealNavigation = nil
        }
      }
    }
    .tabItem {
      Label("Nutrition", image: .nutritionTab)
    }
  }
}

private extension NutritionView {
  var topBar: some View {
    FoodLogDatePicker(date: $nutritionViewModel.date) { date in
      if let state = nutritionViewModel.dateStates.first(where: { Calendar.current.isDate(date, inSameDayAs: $0.date) })?.state {
        return state
      }
      return .inProgress(0)
    }
  }
}

private extension NutritionView {
  struct FilteredFoodItemLogsListView: View {

    @Binding private var presentedSheet: AnyView?

    init(
      date: Date,
      presentedSheet: Binding<AnyView?>
    ) {
      self._presentedSheet = presentedSheet

      let startOfDay = Calendar.current.startOfDay(for: date)
      let endOfDay = Calendar.current.endOfDay(for: date)

      self._foodItemLogs = Query(
        filter: #Predicate<FoodItemLog> { log in
          log.date >= startOfDay &&
          log.date <= endOfDay
        },
        sort: \FoodItemLog.date,
        order: .forward
      )
    }

    @ObservedObject private var nutritionViewModel = NutritionTrackingViewModel.shared

    @Query private var foodItemLogs: [FoodItemLog]

    var body: some View {
      Group {
        ForEach(FoodItemLog.Meal.allCases) { meal in
          NutritionMealView(
            meal: meal,
            foodItemLogs: foodItemLogs(for: meal),
            presentedSheet: $presentedSheet
          ) { foodItemLog, foodItem in
            presentedSheet = FoodItemDetailsView(
              foodItem: foodItem.asNetworkFoodItem(),
              existingFoodItemLog: foodItemLog
            ).asAny
          } showMealDetails: { foodItemLog in
            presentedSheet = FoodItemLogDetailsView(foodItemLog: foodItemLog).asAny
          } onLogTapped: {
            nutritionViewModel.suggestedMeal = meal
            presentedSheet = FoodLoggingActionCardView().asAny
          }
          .padding(.vertical)
        }
      }
    }
  }
}

private extension NutritionView.FilteredFoodItemLogsListView {

  func foodItemLogs(for meal: FoodItemLog.Meal) -> [FoodItemLog] {
    foodItemLogs.filter {
      $0.meal == meal
    }
  }
}

#Preview {
  PreviewEnvironment {
    NutritionView()
  }
}
