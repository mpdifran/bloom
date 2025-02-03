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
          vitaminsSection
        }
        .padding()
      }
      .groupedBackground()
      .navigationTitle("Report an Issue")
    }
  }
}

private extension FoodItemIssueReportView {

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
}

#Preview {
  FoodItemIssueReportView(foodItem: .Preview.ritzCrackers)
}
