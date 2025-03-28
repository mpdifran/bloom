//
//  ContentView.swift
//  SwiftData-Repro
//
//  Created by Zach Radford on 2025-03-24.
//

import SwiftUI
import SwiftData

struct ContentView: View {
  @Environment(\.modelContext) private var modelContext

  @Query private var logs: [FoodItemLog]
  @Query private var habits: [Habit]

  var body: some View {
    NavigationStack {
      List {
        ForEach(logs) { log in
          FoodItemLogView(log: log)
        }
        ForEach(habits) { habit in
          HabitView(habit: habit)
        }
      }
      .toolbar {
        ToolbarItem {
          Button {
            addFood()
          } label: {
            Text("Add Food")
          }
        }
        ToolbarItem {
          Button {
            addHabit()
          } label: {
            Text("Add Habit")
          }
        }
      }
    }
  }

  private func addFood() {
    let newLog = FoodItemLog(
      id: UUID().uuidString,
      date: .now,
      meal: .breakfast,
      numberOfServings: 1,
      foodItem: TestData.ritzCrackers
    )
    modelContext.insert(newLog)
    try? modelContext.save()
  }

  private func addHabit() {
    let newHabit = Habit(
      targetMetric: .proteinIntake,
      value: 7,
      unitString: "g",
      startDate: .now,
      isSuggested: true,
      isUserEdited: false
    )
    modelContext.insert(newHabit)
    try? modelContext.save()
  }
}

struct FoodItemLogView: View {
  let log: FoodItemLog

  var body: some View {
    VStack {
      Text(log.id)
      Text(log.date, style: .date)
      Text(log.meal.rawValue)
      Text("\(log.numberOfServings)")
    }
    .background(.red)
  }
}

struct HabitView: View {
  let habit: Habit

  var body: some View {
    VStack {
      Text(habit.rawTargetMetric)
      Text("\(habit.value)")
      Text(habit.unitString)
      Text(habit.startDate, style: .date)
    }
    .background(.blue)
  }
}

enum TestData {
  static let ritzCrackers = FoodItemRecord(
    id: "1234",
    name: "Crackers",
    brandName: "Ritz",
    flavour: "Low Sodium",
    rawCountry: "canada",
    calories: 100,
    protein: 1,
    carbohydrates: 13,
    fat: 4.5,
    saturatedFat: nil,
    transFat: nil,
    polyunsaturatedFat: nil,
    monounsaturatedFat: nil,
    fiber: nil,
    sugar: nil,
    cholesterol: nil,
    sodium: nil,
    calcium: nil,
    iron: nil,
    potassium: nil,
    magnesium: nil,
    zinc: nil,
    vitaminA: nil,
    vitaminB6: nil,
    vitaminB12: nil,
    vitaminC: nil,
    vitaminD: nil,
    vitaminE: nil,
    servingName: "6 crackers",
    servingUnitString: "g",
    servingValue: 20,
    ingredients: "Yogurt (Milk);  Rhubarb (8%);  Sugar;  Tapioca Starch;  Natural Flavourings;  Colour (Plain Caramel);  Stabiliser (Pectin);  Milk Minerals;  Cultures (Lactobacillus Bulgaricus;  Streptococcus Thermophilus;  Lactococcus Lactis;  Bifidobacterium Lactis (Bifidus Actiregularis®))",
    category: .branded,
    isVerified: true
  )
}
