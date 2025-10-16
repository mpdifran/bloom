//
//  LogMealWidget.swift
//  BloomWidgets
//
//  Created by Claude Code on 2025-10-16.
//

import SwiftUI
import WidgetKit

struct LogMealWidget: Widget {
  let kind: String = "com.lotus-labs.bloom.LogMealWidget"

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
    displayName: "Vector - Kellogs",
    mealName: "Breakfast",
    caloriesText: "300 cal",
    proteinGrams: 15,
    carbsGrams: 45,
    fatGrams: 2,
    foodItemNames: nil,
    servingsDescription: "1 serving",
    intent: LogMealIntent(
      foodItems: [FoodItemEntity(
        id: "fooditem_123",
        name: "Vector",
        brandName: "Kellogs",
        flavour: nil,
        calories: 300,
        protein: 15,
        carbs: 45,
        fat: 2
      )],
      mealOption: .breakfast,
      servings: 1
    )
  )
}

#Preview("Multiple Items - Medium", as: .systemMedium) {
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
    intent: LogMealIntent(
      foodItems: [
        FoodItemEntity(id: "1", name: "Oatmeal", brandName: nil, flavour: nil, calories: 150, protein: 5, carbs: 27, fat: 3),
        FoodItemEntity(id: "2", name: "Blueberries", brandName: nil, flavour: nil, calories: 80, protein: 1, carbs: 21, fat: 0),
        FoodItemEntity(id: "3", name: "Almonds", brandName: nil, flavour: nil, calories: 160, protein: 6, carbs: 6, fat: 14)
      ],
      mealOption: .breakfast,
      servings: 1
    )
  )
}
