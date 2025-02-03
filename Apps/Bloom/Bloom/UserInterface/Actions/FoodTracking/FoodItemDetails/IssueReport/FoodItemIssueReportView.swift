//
//  FoodItemIssueReportView.swift
//  Bloom
//
//  Created by Mark DiFranco on 2025-01-30.
//

import SwiftUI
import BloomModel

struct FoodItemIssueReportView: View {
  let foodItem: FoodItem

  init(foodItem: FoodItem) {
    self.foodItem = foodItem

    self._foodItemState = State(initialValue: FoodItemIssueReportState(foodItem: foodItem))
  }

  @State private var foodItemState: FoodItemIssueReportState

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack {
          nameSection
          servingSection
          caloriesSection
          proteinSection
          carbohydrateSection
          fatSection
          cholesterolSection
          mineralsSection
          vitaminsSection
          notesSection
        }
        .padding()
      }
      .groupedBackground()
      .navigationTitle("Report an Issue")
    }
  }
}

private extension FoodItemIssueReportView {

  var nameSection: some View {
    VStack {
      FoodItemNameTextCell(
        title: "Brand Name",
        originalName: foodItem.brandName ?? "",
        name: $foodItemState.brandName
      )

      Divider()

      FoodItemNameTextCell(
        title: "Name",
        originalName: foodItem.name,
        name: $foodItemState.name
      )

      Divider()

      FoodItemNameTextCell(
        title: "Flavour",
        originalName: foodItem.flavour ?? "",
        name: $foodItemState.flavour
      )
    }
    .cardContainer()
  }

  var servingSection: some View {
    VStack {
      FoodItemNameTextCell(
        title: "Serving Name",
        originalName: foodItem.servingName ?? "",
        name: $foodItemState.servingName
      )

      Divider()

      FoodItemNumberTextCell(
        title: "Serving Value",
        originalValue: foodItem.servingQuantity?.value ?? 0,
        value: $foodItemState.servingValue
      )

      Divider()

      FoodItemNameTextCell(
        title: "Serving Unit",
        originalName: foodItem.servingQuantity?.unit ?? "",
        name: $foodItemState.servingUnit
      )
    }
    .cardContainer()
  }

  var caloriesSection: some View {
    VStack {
      NutrientIssueReportCell(
        name: "Calories",
        originalQuantity: foodItem.calories?.hkQuantity,
        amount: $foodItemState.calories,
        unit: .constant(.largeCalorie()),
        validUnits: [.largeCalorie()]
      )
    }
    .cardContainer()
  }

  var proteinSection: some View {
    VStack {
      NutrientIssueReportCell(
        name: "Protein",
        originalQuantity: foodItem.protein?.hkQuantity,
        amount: $foodItemState.protein,
        unit: .constant(.gram()),
        validUnits: [.gram()]
      )
    }
    .cardContainer()
  }

  var carbohydrateSection: some View {
    VStack {
      NutrientIssueReportCell(
        name: "Carbohydrates",
        originalQuantity: foodItem.carbohydrates?.hkQuantity,
        amount: $foodItemState.carbohydrates,
        unit: .constant(.gram()),
        validUnits: [.gram()]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Fiber",
        originalQuantity: foodItem.fiber?.hkQuantity,
        amount: $foodItemState.fiber,
        unit: .constant(.gram()),
        validUnits: [.gram()]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Sugar",
        originalQuantity: foodItem.sugar?.hkQuantity,
        amount: $foodItemState.sugar,
        unit: .constant(.gram()),
        validUnits: [.gram()]
      )
    }
    .cardContainer()
  }

  var fatSection: some View {
    VStack {
      NutrientIssueReportCell(
        name: "Fat",
        originalQuantity: foodItem.fat?.hkQuantity,
        amount: $foodItemState.fat,
        unit: .constant(.gram()),
        validUnits: [.gram()]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Saturated Fat",
        originalQuantity: foodItem.saturatedFat?.hkQuantity,
        amount: $foodItemState.saturatedFat,
        unit: .constant(.gram()),
        validUnits: [.gram()]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Trans Fat",
        originalQuantity: foodItem.transFat?.hkQuantity,
        amount: $foodItemState.transFat,
        unit: .constant(.gram()),
        validUnits: [.gram()]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Polyunsaturated Fat",
        originalQuantity: foodItem.polyunsaturatedFat?.hkQuantity,
        amount: $foodItemState.polyunsaturatedFat,
        unit: .constant(.gram()),
        validUnits: [.gram()]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Monounsaturated Fat",
        originalQuantity: foodItem.monounsaturatedFat?.hkQuantity,
        amount: $foodItemState.monounsaturatedFat,
        unit: .constant(.gram()),
        validUnits: [.gram()]
      )

    }
    .cardContainer()
  }

  var cholesterolSection: some View {
    VStack {
      NutrientIssueReportCell(
        name: "Cholesterol",
        originalQuantity: foodItem.cholesterol?.hkQuantity,
        amount: $foodItemState.cholesterol,
        unit: .constant(.gram()),
        validUnits: [.gram()]
      )
    }
    .cardContainer()
  }

  var mineralsSection: some View {
    VStack {
      NutrientIssueReportCell(
        name: "Sodium",
        originalQuantity: foodItem.sodium?.hkQuantity,
        amount: $foodItemState.sodium,
        unit: .constant(.gramUnit(with: .milli)),
        validUnits: [.gramUnit(with: .milli)]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Calcium",
        originalQuantity: foodItem.calcium?.hkQuantity,
        amount: $foodItemState.calcium,
        unit: .constant(.gramUnit(with: .milli)),
        validUnits: [.gramUnit(with: .milli)]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Iron",
        originalQuantity: foodItem.iron?.hkQuantity,
        amount: $foodItemState.iron,
        unit: .constant(.gramUnit(with: .milli)),
        validUnits: [.gramUnit(with: .milli)]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Potassium",
        originalQuantity: foodItem.potassium?.hkQuantity,
        amount: $foodItemState.potassium,
        unit: .constant(.gramUnit(with: .milli)),
        validUnits: [.gramUnit(with: .milli)]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Magnesium",
        originalQuantity: foodItem.magnesium?.hkQuantity,
        amount: $foodItemState.magnesium,
        unit: .constant(.gramUnit(with: .milli)),
        validUnits: [.gramUnit(with: .milli)]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Zinc",
        originalQuantity: foodItem.zinc?.hkQuantity,
        amount: $foodItemState.zinc,
        unit: .constant(.gramUnit(with: .milli)),
        validUnits: [.gramUnit(with: .milli)]
      )
    }
    .cardContainer()
  }

  var vitaminsSection: some View {
    VStack {
      NutrientIssueReportCell(
        name: "Vitamin A",
        originalQuantity: foodItem.vitaminA?.hkQuantity,
        amount: $foodItemState.vitaminA,
        unit: .constant(.gramUnit(with: .micro)),
        validUnits: [.gramUnit(with: .micro)]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Vitamin B6",
        originalQuantity: foodItem.vitaminB6?.hkQuantity,
        amount: $foodItemState.vitaminB6,
        unit: .constant(.gramUnit(with: .micro)),
        validUnits: [.gramUnit(with: .micro)]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Vitamin B12",
        originalQuantity: foodItem.vitaminB12?.hkQuantity,
        amount: $foodItemState.vitaminB12,
        unit: .constant(.gramUnit(with: .micro)),
        validUnits: [.gramUnit(with: .micro)]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Vitamin C",
        originalQuantity: foodItem.vitaminC?.hkQuantity,
        amount: $foodItemState.vitaminC,
        unit: .constant(.gramUnit(with: .micro)),
        validUnits: [.gramUnit(with: .micro)]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Vitamin D",
        originalQuantity: foodItem.vitaminD?.hkQuantity,
        amount: $foodItemState.vitaminD,
        unit: .constant(.gramUnit(with: .micro)),
        validUnits: [.gramUnit(with: .micro)]
      )

      Divider()

      NutrientIssueReportCell(
        name: "Vitamin E",
        originalQuantity: foodItem.vitaminE?.hkQuantity,
        amount: $foodItemState.vitaminE,
        unit: .constant(.gramUnit(with: .micro)),
        validUnits: [.gramUnit(with: .micro)]
      )
    }
    .cardContainer()
  }

  var notesSection: some View {
    VStack {
      FoodItemIssueTextFieldCell(title: "Notes", text: $foodItemState.notes)
    }
    .cardContainer()
  }
}

#Preview {
  FoodItemIssueReportView(foodItem: .Preview.ritzCrackers)
}
