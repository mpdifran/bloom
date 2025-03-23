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
  @State private var advanceToggle = false

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          topBar

          NutrientsRemainingView()
            .padding(.vertical)
            .onTapGesture {
              // TODO: where does this go?
            }

          FilteredFoodItemLogsListView(
            date: nutritionViewModel.date,
            presentedSheet: $presentedSheet
          )
        }
        .padding()
      }
      .groupedBackground()
      .navigationBarTitleDisplayMode(.inline)
      .tabBar()
      .toolbar {
        ToolbarItem(placement: .principal) {
          FoodItemLogDatePicker()
        }
        ToolbarItem(placement: .primaryAction) {
          Button {
            EntitledPresent(presentedSheet: $presentedSheet) {
              FoodLoggingActionCardView()
            }
          } label: {
            Image(systemSymbol: .plus)
              .bold()
          }
        }
      }
    }
    .sheet($presentedSheet)
    .tabItem {
      Label("Nutrition", systemSymbol: .carrot)
    }
  }
}

private extension NutritionView {
  var topBar: some View {
    HStack {
      Button {
        nutritionViewModel.reverseDay()
        advanceToggle.toggle()
      } label: {
        Image(systemSymbol: .chevronBackwardCircleFill)
          .font(.title2)
          .bold()
          .foregroundStyle(.white, .tint)
      }

      Spacer()

      Button {
        nutritionViewModel.advanceDay()
        advanceToggle.toggle()
      } label: {
        Image(systemSymbol: .chevronForwardCircleFill)
          .font(.title2)
          .bold()
          .foregroundStyle(.white, .tint)
      }
    }
    .sensoryFeedback(.impact, trigger: advanceToggle)
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
  TabView {
    NutritionView()
  }
}
