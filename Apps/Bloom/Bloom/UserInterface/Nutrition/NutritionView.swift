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
          NutrientsRemainingView()
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
            EntitledPresent(presentedSheet: $presentedSheet) {
              FoodLoggingActionCardView()
            }
          } label: {
            Image(systemSymbol: .plus)
              .bold()
          }
        }

        ToolbarItem(placement: .primaryAction) {
          Button {
            presentedSheet = SettingsView().asAny
          } label: {
            UserProfilePhotoView(dimension: 32)
          }
        }
      }
    }
    .animation(.easeInOut, value: nutritionViewModel.date)
    .sheet($presentedSheet)
    .tabItem {
      Label("Nutrition", systemSymbol: .carrot)
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
            foodItemLogs: foodItemLogs(for: meal)
          ) { foodItemLog, foodItem in
            presentedSheet = FoodItemDetailsView(
              foodItem: foodItem.asNetworkFoodItem(),
              existingFoodItemLog: foodItemLog
            ).asAny
          } showMealDetails: { foodItemLog in
            presentedSheet = FoodItemLogDetailsView(foodItemLog: foodItemLog).asAny
          } onLogTapped: {
            nutritionViewModel.suggestedMeal = meal
            EntitledPresent(presentedSheet: $presentedSheet) {
              FoodLoggingActionCardView()
            }
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
