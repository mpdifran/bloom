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
                meal: nutritionViewModel.suggestedMeal
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
                nutritionViewModel.reverseTimeWindow()
                advanceToggle.toggle()
            } label: {
                Image(systemName: "chevron.backward.circle.fill")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.tint, .tint.secondary)
            }
            .sensoryFeedback(.impact, trigger: advanceToggle)

            Spacer()

            FoodItemLogDatePicker()
            MealPicker()

            Spacer()

            Button {
                nutritionViewModel.advanceTimeWindow()
                advanceToggle.toggle()
            } label: {
                Image(systemName: "chevron.forward.circle.fill")
                    .font(.title2)
                    .bold()
                    .foregroundStyle(.tint, .tint.secondary)
            }
            .sensoryFeedback(.impact, trigger: advanceToggle)
        }

        Divider()
    }
}

private extension NutritionStatusCard {
    private struct FilteredFoodItemLogsListView: View {

        init(date: Date, meal: FoodItemLog.Meal) {
            let startOfDay = Calendar.current.startOfDay(for: date)
            let endOfDay = Calendar.current.endOfDay(for: date)

            self._foodItemLogs = Query(
                filter: #Predicate<FoodItemLog> { log in
                    log.date >= startOfDay &&
                    log.date <= endOfDay &&
                    log.meal == meal // TODO: This never matches
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
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 100)
                } else {
                    ForEach(foodItemLogs) { foodItemLog in
                        FoodItemLogCell(foodItemLog: foodItemLog)
                            .transition(.blurReplace)
                            .padding(.vertical)
                        Divider()
                    }
                }
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
