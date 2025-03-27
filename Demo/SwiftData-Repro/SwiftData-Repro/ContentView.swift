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

  var body: some View {
    NavigationStack {
      List(logs) { log in
        FoodItemLogView(log: log)
      }
      .toolbar {
          ToolbarItem {
              Button(action: addItem) {
                  Label("Add Item", systemImage: "plus")
              }
          }
      }
    }
  }

  private func addItem() {
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
    isVerified: true,
    logs: []
  )
}
