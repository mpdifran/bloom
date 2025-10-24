//
//  LogMealWidget.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-16.
//

import SwiftUI
import WidgetKit
import BloomFoundation

struct LogMealWidget: Widget {
  let kind: String = .WidgetKind.logMeal

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      intent: LogMealConfigurationIntent.self,
      provider: LogMealTimelineProvider()
    ) { entry in
      LogMealWidgetView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Log Meal")
    .description("Quickly log a meal with one or more food items.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}

#Preview("Single Item - Small", as: .systemSmall) {
  LogMealWidget()
} timeline: {
  LogMealEntry(
    date: .now,
    displayName: "Vector",
    mealName: "Breakfast",
    caloriesText: "300 cal",
    proteinGrams: 15,
    carbsGrams: 45,
    fatGrams: 2,
    foodItemNames: nil,
    servingsDescription: "1 serving",
    intent: LogMealToggleIntent(
      kind: .singleFoodItem,
      foodItem: FoodItemEntity(
        id: "fooditem_123",
        name: "Vector",
        brandName: "Kellogs",
        flavour: nil,
        calories: 300,
        protein: 15,
        carbs: 45,
        fat: 2
      ),
      savedMeal: nil,
      meal: .breakfast,
      servings: 1.0
    )
  )
}

#Preview("Saved Meal - Medium", as: .systemMedium) {
  LogMealWidget()
} timeline: {
  LogMealEntry(
    date: .now,
    displayName: "Breakfast Bowl",
    mealName: "Breakfast",
    caloriesText: "390 cal",
    proteinGrams: 12,
    carbsGrams: 54,
    fatGrams: 17,
    foodItemNames: "Oatmeal, Blueberries, and Almonds",
    servingsDescription: "1 serving",
    intent: LogMealToggleIntent(
      kind: .savedMeal,
      foodItem: nil,
      savedMeal: MealEntity(id: "meal_123", name: "Breakfast Bowl"),
      meal: .breakfast,
      servings: 1.0
    )
  )
}
