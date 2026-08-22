//
//  NutritionScreenshot.swift
//  Bloom
//

import SwiftUI
import AppUI
import BloomFoundation
import BloomUI
import CoreHealth
import SFSafeSymbols

/// The Nutrition tab, as it appears in the App Store screenshots.
///
/// The date strip and meal headers are the app's real components. The macro card and food rows are
/// recomposed rather than reused: `NutrientsWidgetView` and `FoodItemLogCell` are driven by
/// `@Query` and SwiftData models, which a fixture-only preview has no context to provide.
struct NutritionScreenshot: View {
  let fixtures: ScreenshotFixtures

  private var capturedAt: Date {
    DateComponents(
      calendar: Calendar(identifier: .gregorian),
      timeZone: TimeZone(identifier: "America/Toronto"),
      year: 2026, month: 2, day: 7
    ).date ?? .now
  }

  private var weekDates: [Date] {
    let calendar = Calendar(identifier: .gregorian)
    return (-2...2).compactMap { calendar.date(byAdding: .day, value: $0, to: capturedAt) }
  }

  var body: some View {
    NavigationStack {
      BloomScrollView(spacing: 20) {
        dateStrip

        VStack(alignment: .leading, spacing: 8) {
          Text("Macros")
            .font(.headline)
          macrosCard
        }

        ForEach(fixtures.meals) { meal in
          VStack(alignment: .leading, spacing: 8) {
            MealHeaderView(
              mealName: meal.name,
              totalCalories: meal.calories,
              totalProtein: meal.protein,
              totalCarbs: meal.carbs,
              totalFat: meal.fat,
              onLogTapped: { },
              onSaveAsMeal: nil
            )

            ForEach(meal.items) { item in
              foodRow(item)
                .cardContainer()
            }
          }
        }
      }
      .navigationTitle("Nutrition")
      .toolbar {
        SettingsProfileViewToolbarButton()

        ToolbarItem(placement: .topBarLeading) {
          Button { } label: {
            Image(systemSymbol: .plus)
          }
          .buttonStyle(.plain)
          .bold()
        }
      }
    }
  }
}

private extension NutritionScreenshot {

  var dateStrip: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(fixtures.todayDate(capturedAt))
          .font(.subheadline)
          .foregroundStyle(.secondary)

        Spacer()

        Text("Today")
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      HStack(spacing: 12) {
        ForEach(weekDates, id: \.self) { date in
          FoodLogDateCell(
            date: date,
            state: fixtures.dateState(for: date, capturedAt: capturedAt),
            isSelected: Calendar.current.isDate(date, inSameDayAs: capturedAt)
          )
        }
      }
    }
  }

  var macrosCard: some View {
    HStack {
      VStack(alignment: .leading) {
        Text(fixtures.totalCalories.format(using: .noDecimalPlaces))
          .font(.title)
          .bold()
          .fontDesign(.rounded)
        Text("Calories")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()

      macro(value: fixtures.totalProtein, name: "Protein", color: .mutedBlue)
      macro(value: fixtures.totalCarbs, name: "Carbs", color: .blue)
      macro(value: fixtures.totalFat, name: "Fats", color: .mutedOrange)
    }
    .cardContainer()
  }

  func macro(value: Double, name: LocalizedStringKey, color: Color) -> some View {
    VStack {
      Text("\(value.format(using: .noDecimalPlaces)) g")
        .font(.title3)
        .bold()
        .fontDesign(.rounded)
        .foregroundStyle(color)
      Text(name)
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding(.horizontal, 8)
  }

  func foodRow(_ item: ScreenshotFixtures.FoodRow) -> some View {
    HStack {
      Image(systemSymbol: .checkmarkShieldFill)
        .foregroundStyle(.mutedGreen)

      VStack(alignment: .leading) {
        Text(item.name)
          .font(.headline)
        Text(item.detail)
          .font(.subheadline)
          .foregroundStyle(.secondary)
      }

      Spacer()

      Text("\(item.calories.format(using: .noDecimalPlaces)) cals")
        .font(.headline)
        .foregroundStyle(.secondary)

      Image(systemSymbol: .chevronForward)
        .foregroundStyle(.tertiary)
    }
  }
}

#Preview("Nutrition") {
  ScreenshotPreviewHost(selectedTab: .nutrition) { fixtures in
    NutritionScreenshot(fixtures: fixtures)
  }
}
