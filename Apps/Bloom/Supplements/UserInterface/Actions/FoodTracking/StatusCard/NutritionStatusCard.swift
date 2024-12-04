//
//  NutritionStatusCard.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-26.
//

import SwiftUI
import AppUI
import DataContainer
import SwiftData

struct NutritionStatusCard: View {

  @State private var nutritionViewModel = NutritionTrackingViewModel.shared
  @State private var presentedSheet: AnyView?
  @State private var advanceToggle = false

  var body: some View {
    VStack(spacing: 0) {
      topBarView

      FilteredFoodItemLogsListView(
        date: nutritionViewModel.date,
        presentedSheet: $presentedSheet
      )
      .animation(.default, value: nutritionViewModel.date)
      .animation(.default, value: nutritionViewModel.suggestedMeal)

      Button("Log Food", systemImage: "plus") {
        presentedSheet = FoodLoggingActionCardView().asAny
      }
      .bold()
      .frame(minHeight: 50)
    }
    .horizontallyCentered()
    .padding(.horizontal)
    .cardContainer(fill: .tint.quinary, stroke: .tint.quaternary, includePadding: false)
    .tint(.mutedGreen)
    .sheet($presentedSheet)
  }
}

private extension NutritionStatusCard {

  @ViewBuilder
  var topBarView: some View {
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

      FoodItemLogDatePicker()

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

    Divider()
  }
}

private extension NutritionStatusCard {
  private struct FilteredFoodItemLogsListView: View {

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

    @Query private var foodItemLogs: [FoodItemLog]

    var body: some View {
      Group {
        if foodItemLogs.isEmpty {
          VStack {
            Text("No Food Logged")
              .font(.title2)
              .bold()
          }
          .foregroundStyle(.tint.secondary)
          .frame(height: 100)
        } else {
          ForEach(FoodItemLog.Meal.allCases) { meal in
            SectionTitleView(meal.name)
              .padding(.top)

            if foodItemLogs(for: meal).isEmpty {
              VStack {
                Text("No Food Logged")
                  .font(.title2)
                  .bold()
              }
              .foregroundStyle(.tint.secondary)
              .frame(height: 60)
            } else {
              ForEach(foodItemLogs(for: meal)) { foodItemLog in
                FoodItemLogCell(foodItemLog: foodItemLog)
                  .id(foodItemLog.id)
                  .transition(.blurReplace)
                  .selectable()
                  .onTapGesture {
                    guard let foodItem = foodItemLog.foodItem else { return }

                    presentedSheet = FoodItemDetailsView(
                      foodItem: foodItem.asNetworkFoodItem(),
                      existingFoodItemLog: foodItemLog
                    ).asAny
                  }
                  .padding(.vertical)
                Divider()
              }
            }
          }
        }
      }
    }

    private func foodItemLogs(for meal: FoodItemLog.Meal) -> [FoodItemLog] {
      foodItemLogs.filter {
        $0.meal == meal
      }
    }
  }
}

#Preview {
  ScrollView {
    VStack {
      NutritionStatusCard()
    }
    .padding()
  }
}
