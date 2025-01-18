//
//  NutritionView.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-12-04.
//

import SwiftUI
import AppUI
import DataContainer
import SwiftData

struct NutritionView: View {

  @State private var nutritionViewModel = NutritionTrackingViewModel.shared
  @State private var presentedSheet: AnyView?

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          FilteredFoodItemLogsListView(
            date: nutritionViewModel.date,
            presentedSheet: $presentedSheet
          )
        }
        .horizontallyCentered()
        .padding()
      }
      .groupedBackground()
      .navigationBarTitleDisplayMode(.inline)
      .tabBar()
      .tint(.mutedGreen)
      .toolbar {
        ToolbarItem(placement: .principal) {
          FoodItemLogDatePicker()
        }
        ToolbarItem(placement: .primaryAction) {
          Button {
            presentedSheet = FoodLoggingActionCardView().asAny
          } label: {
            Image(systemName: "plus")
              .bold()
          }
        }
      }
    }
    .tint(.mutedGreen)
    .sheet($presentedSheet)
    .tabItem {
      Label("Nutrition", systemImage: "carrot")
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

    @State private var nutritionViewModel = NutritionTrackingViewModel.shared
    @State private var advanceToggle = false

    @Query private var foodItemLogs: [FoodItemLog]

    var body: some View {
      VStack {
        topBar

        Divider()

        ForEach(FoodItemLog.Meal.allCases) { meal in
          NutritionMealView(
            meal: meal,
            foodItemLogs: foodItemLogs(for: meal)
          ) { foodItemLog in
            guard let foodItem = foodItemLog.foodItem else { return }

            presentedSheet = FoodItemDetailsView(
              foodItem: foodItem.asNetworkFoodItem(),
              existingFoodItemLog: foodItemLog
            ).asAny
          } onLogTapped: {
            nutritionViewModel.suggestedMeal = meal
            presentedSheet = FoodLoggingActionCardView().asAny
          }
        }
      }
    }
  }
}

private extension NutritionView.FilteredFoodItemLogsListView {

  var topBar: some View {
    HStack {
      Button {
        nutritionViewModel.reverseDay()
        advanceToggle.toggle()
      } label: {
        Image(systemName: "chevron.backward.circle.fill")
          .font(.title2)
          .bold()
          .foregroundStyle(.white, .tint)
      }

      Spacer()

      Text("\(totalCalories.format()) Cals")
        .font(.title3)
        .bold()

      Spacer()

      Button {
        nutritionViewModel.advanceDay()
        advanceToggle.toggle()
      } label: {
        Image(systemName: "chevron.forward.circle.fill")
          .font(.title2)
          .bold()
          .foregroundStyle(.white, .tint)
      }
    }
    .sensoryFeedback(.impact, trigger: advanceToggle)
  }

  func foodItemLogs(for meal: FoodItemLog.Meal) -> [FoodItemLog] {
    foodItemLogs.filter {
      $0.meal == meal
    }
  }

  var totalCalories: Double {
    foodItemLogs.reduce(0) { partialResult, foodItemLog in
      partialResult + foodItemLog.totalCalories
    }
  }
}

#Preview {
  TabView {
    NutritionView()
  }
}
