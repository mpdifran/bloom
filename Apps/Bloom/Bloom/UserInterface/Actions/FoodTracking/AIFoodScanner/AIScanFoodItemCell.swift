//
//  AIScanFoodItemCell.swift
//  Supplements
//
//  Created by Mark DiFranco on 2024-11-24.
//

import SFSafeSymbols
import SwiftUI
import BloomModel

/// This is inspired by `FoodItemCell`.
struct AIScanFoodItemCell: View {
  @Binding var foodItemServing: FoodItemServing

  /// This is needed since there's a bug when editing a @Binding of a Double, compared to a @State of a Double. The latter is much nicer, and the former is a pain in the ass.
  @State private var internalFoodItemServingAmount: Double

  @FocusState private var isFocused: Bool

  init(foodItemServing: Binding<FoodItemServing>) {
    self._foodItemServing = foodItemServing
    self._internalFoodItemServingAmount = State(initialValue: foodItemServing.wrappedValue.serving)
  }

  var body: some View {
    HStack {
      foodDetailsContentView

      Spacer()

      caloriesView
      editContentView
    }
    .onChange(of: isFocused) { oldValue, newValue in
      guard !newValue && oldValue else { return }

      foodItemServing.serving = internalFoodItemServingAmount
    }
    .cardContainer(fill: .background, stroke: .background.secondary)
  }
}

private extension AIScanFoodItemCell {

  var food: FoodItem {
    foodItemServing.foodItem
  }

  var foodDetailsContentView: some View {
    VStack(alignment: .leading) {
      HStack(spacing: 4) {
        if food.isVerified {
          Image(systemSymbol: .checkmarkShieldFill)
            .foregroundStyle(.white, .mutedGreen)
          Text("Verified")
            .foregroundStyle(.mutedGreen)
            .bold()
        }

        if let brandName = food.brandName, brandName.isNotEmpty {
          Text(brandName)
            .foregroundStyle(.secondary)
            .bold()
        }
      }
      .font(.caption)

      HStack(alignment: .firstTextBaseline) {
        Text(food.name)
        if let flavour = food.flavour {
          Text(flavour)
            .foregroundStyle(.secondary)
            .font(.caption)
        }
      }
      .bold()

      if
        let serving = food.servingName,
        let servingQuantity = food.servingQuantity
      {
        Text("\(serving) (\(servingQuantity.value.format()) \(servingQuantity.unit))")
          .font(.caption)
      }
    }
  }

  @ViewBuilder
  var caloriesView: some View {
    if let calories = food.calories?.value {
      VStack(spacing: 0) {
        Text("\(calories.format())")
          .bold()
          .font(.title2)
          .foregroundStyle(.tint)
        Text("cals")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .fontDesign(.rounded)
    }
  }

  var editContentView: some View {
    HStack {
      VStack {
        TextField("", value: $internalFoodItemServingAmount, formatter: NumberFormatter.threeDecimalPlaces)
          .textFieldStyle(.roundedBorder)
          .multilineTextAlignment(.trailing)
          .frame(width: 70)
          .fontDesign(.rounded)
          .keyboardType(.decimalPad)
          .selectAllTextOnBeginEditing()
          .focused($isFocused)

        Text("servings")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

#Preview {
  AIScanFoodItemCell(
    foodItemServing: .constant(
      FoodItemServing(
        serving: 2,
        foodItem: .Preview.ritzCrackers
      )
    )
  )
  .padding()
}
